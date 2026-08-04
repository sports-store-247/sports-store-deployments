# Context

Running notes from the 8 DOC-precedence sources, keyed by topic. Verbatim-faithful with
source attribution. DOC is the lowest precedence tier — nothing here overrides
`STATUS.md` (PRD, prec 1) or the two SPECs.

---

## Topic: current deployment architecture

- **source:** `STATUS.md` (PRD, prec 1) §Snapshot; `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` (DOC)

Stage 3+ — Helm umbrella + Argo CD GitOps + ESO restructure landed on `main`.
Chart: `helm/sports-store` (parent chart, Bitnami MongoDB dependency, vendored
`charts/mongodb-16.5.20.tgz`). GitOps: `argocd-app.yaml` (AppProject + Application,
automated sync). Public domain: `https://sportsstore.seansite.org/`.

Rendered inventory (32 resources, `helm template --namespace sports-store`, exit 0,
1519 lines):

```
Namespace       -> sports-store
ServiceAccount  -> sports-store-mongodb, app-secrets-sa (IRSA annotated)
NetworkPolicy/PDB -> sports-store-mongodb
ConfigMap       -> auth/cart/order/payment-config, sports-store-mongodb-common-scripts,
                   mongo-init (blank namespace - R4)
Service         -> sports-store-mongodb, auth/cart/catalog/gateway/order/payment-service
Deployment      -> sports-store-mongodb, auth/cart/catalog/gateway/order/payment-service
Ingress         -> sports-store-gateway
ExternalSecret  -> app-secrets-eso, mongodb-credentials-eso
SecretStore     -> aws-secrets-manager
ServiceMonitor  -> sports-store-{auth,cart,catalog,gateway,order,payment}-service
```

Frontend renders no workload — not in `.Values.services`.

## Topic: verification evidence — post-merge full risk scan (current)

- **source:** `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` (DOC)
- **branch:** `gsd/post-merge-full-risk-scan` (in sync with `main`)

Method: `helm lint ./helm/sports-store` → 1 chart linted, 0 failed (only
`icon is recommended` INFO). `helm template` with production `values.yaml` + `images.yaml`
→ exit 0, 1519 lines, no stderr, MongoDB rendered offline.

Verified PASS:
- [1] Lint pass. [2] Render exit 0, namespace-aware.
- [4] Namespace consistency across all resources **except** `ConfigMap/mongo-init`.
- [5] Ingress backend `service.name: gateway`, `port.number: 80` matches rendered
  `Service/gateway` (ClusterIP, port 80) — F3 stays fixed.
- [7] `Service/sports-store-mongodb` port 27017; in-cluster DNS
  `sports-store-mongodb.sports-store.svc:27017`. `MONGO_URI` host strings live in AWS
  Secrets Manager, not the chart.
- [8] All 6 app images `0.1.0-<7char-hash>` — auth `686e7cd`, cart `6e0f5cc`,
  catalog `06243ee`, gateway `11ea172`, order `1661894`, payment `2738bd5`; MongoDB
  `mongo:8.0`. No `latest`. F1 resolved.
- [9] ESO wiring consistent — `app-secrets-eso` target Secret is `app-secrets`; every app
  Deployment `secretKeyRef.name` is `app-secrets`.

Boundary: template render only, nothing applied to a cluster, E2E not verified.

## Topic: risk → failure-mode mapping

- **source:** `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` (DOC) §[10]

| Failure mode | Cause(s) | Owner |
|---|---|---|
| ALB 503 | Gateway pods unhealthy from missing `app-secrets` (R3) or Mongo unreachable (R2/R3); ALB controller must be installed | Sean + Daniel |
| Pods not ready | `app-secrets` never synced (R3) | Sean |
| Missing secrets | ESO operator / `sports-store/production` / IRSA absent | Sean |
| Mongo resolution failure | `*_MONGO_URI` ≠ `sports-store-mongodb:27017`; data wiped each restart (R2) | Sean + David |
| Metrics not scraped | ServiceMonitor selector mismatch (R1); `/metrics` missing (R5) | David + Daniel |
| Argo CD sync problems | ESO CRDs must exist before sync; `mongo-init` ns (R4) | Sean + David |
| Demo failure | Compound of R2 + R3 + R1 | cross-team |

This mapping is the most useful single artifact for phase sequencing: it shows R1 (David)
and R5 (Daniel) are jointly required for metrics, and that demo failure is compound.

## Topic: superseded verification evidence — earlier helm template render

- **source:** `gsd/verifications/2026-08-03-helm-template-render.md` (DOC)
- **status: SUPERSEDED** by the post-merge risk scan per `STATUS.md`, which labels it the
  "prior render report"

Rendered from `origin/main` via `git archive` into a scratch dir (working tree was on
`docs/helm-secret-bootstrap`, 14 commits behind). helm v4.2.1, exit 0, 1327 lines.

Findings **that no longer hold** (all resolved per `STATUS.md`):
- (1) No ServiceMonitor renders — `grep -c "kind: ServiceMonitor"` = 0.
- (2) Root cause: `templates/servicemonitor.yaml` ranged over undefined
  `.Values.microservices` instead of `.Values.services`. → since fixed; 6 now render.
- (3)(4) All 6 images resolved to `0.1.0-latest`, violating the `<semver>-<7-char-git-hash>`
  brief. → F1 since resolved.
- (7) `templates/ingress.yaml` duplicate `service.name` key (`name: gateway` then
  `name: {{ $.Release.Name }}-gateway`) → backend resolved to non-existent Service
  `sports-store-gateway`. Elevated at the time from cosmetic to functional routing defect.
  → F3 since fixed.

Findings **that still hold**:
- (5) Gateway is the only Ingress — host `sportsstore.seansite.org`,
  `ingressClassName: alb`, internet-facing, ACM cert, health-check `/health`.
- (6) `argocd-app.yaml` duplicate `name:` at lines 20-21 → Application named `cloudcart`.
- ESO restructure renders; the old empty `secret.yaml` is gone.

**Value retained:** this note is the historical record of *why* the current state is
correct, and it documents the `microservices`-vs-`services` class of bug — worth keeping
in mind for REQ-servicemonitor-label-match, which is a second, different defect in the
same template.

## Topic: org delta — cross-repo sweep

- **source:** `gsd/research/2026-08-03-org-delta-monitor.md`, `gsd/repo-feedback/2026-08-03-org-delta-summary.md`, `gsd/research/2026-08-03-team-status-update.md` (all DOC)

Full `git fetch --prune` sweep across all 10 repos.

Resolved / advanced:
- **OIDC regression RESOLVED** — all 7 service repos merged
  `fix: revert to OIDC role-to-assume for AWS credentials`. Cross-team security blocker
  closed (Sean/CI decision).
- `:latest` fixed in the service repos' CI (image build side), across 7 repositories.
- Required extension **declared** (`sports-store-infrastructure` #6); implementation not
  verified (cross-team).
- Deployments restructure landed on `main` (#17/#18): Argo CD AppProject + Application,
  ESO (`externalsecret.yaml`/`secretstore.yaml`/`serviceaccount-eso.yaml`, replacing the
  deleted empty `secret.yaml`), `environments/production/{values,images}.yaml`,
  `ingress.yaml`, `servicemonitor.yaml`, `values-aws.yaml`. **Supersedes** the old
  "app-secrets empty `stringData`" item.

Recent activity:
- deployments `main`: #18 `fix/deployments-restructure`, #17 `fix/gateway-service-name`,
  #16 `docs/helm-secret-bootstrap`.
- infrastructure `main`: #6 declare extension; #5 ALB naming; Argo CD/Grafana ingress domains.
- all 7 service repos: `fix/oidc-regression` merged.

Observed elsewhere (informational, other owners): Terraform naming leftovers
(`FraudstersList`, `FifaApp`) in `argocd.tf`, `prometheus.tf`, `pod-identity.tf`,
`secrets.tf`, `tfc-oidc.tf`; observability gaps (Alertmanager disabled, Grafana auth);
observability stack kube-prometheus / Loki / Alloy.

## Topic: open questions for the team

- **source:** `gsd/repo-feedback/2026-08-03-org-delta-summary.md` and `gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md` (DOC)

Unanswered at ingest time. Several gate David-owned work:

- **Sean:** Is the ESO operator installed? Is Secrets Manager `sports-store/production`
  populated (`JWT_SECRET` + 5 `*_MONGO_URI` + `MONGO_ROOT_PASSWORD`)? Is IRSA
  `sports-store-external-secrets-role` trust-scoped to `app-secrets-sa`/`sports-store`?
- **Sean:** Do the `*_MONGO_URI` values point to `sports-store-mongodb:27017` with the
  correct auth db and credentials? **Is an EBS-backed StorageClass available for R2?**
  ← gates REQ-mongodb-persistence
- **Sean:** Is the AWS Load Balancer Controller installed so the gateway ALB provisions
  and target health can pass?
- **Daniel:** Do the service images expose `/metrics` on their `http` port? Does
  `fix/ci-instrumentator` change that endpoint?
- **Maxim:** Confirm the ownership split for CI-workflow content review (Daniel reports /
  Sean decides) — closes the coordinator plan's self-declared open assumption.

## Topic: recommended next safe action (as written)

- **source:** `gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md` (DOC)

> "Documentation + verification only, in `sports-store-deployments`. Write a
> `gsd/instructions/` plan for R1 (ServiceMonitor label match) and R2 (MongoDB
> persistence), each on its own future branch, then run `helm template` to prove the
> intended selector/label alignment renders. Do NOT edit Helm/Terraform/app/CI. Do NOT
> commit, push, or open a PR. Update STATUS.md Next-up with the plan."

Mirrors `STATUS.md` §"Next up (David's scope)": plan R1 and R2 as `gsd/instructions/`
notes; plan R4 and F2 corrections; confirm frontend intent (F6); get Secrets Manager
content + StorageClass answers from Sean.

## Topic: documentation structure rationale

- **source:** `gsd/research/2026-08-03-docs-bootstrap.md` (DOC)

Intent had been for a single `GSD.md` to hold the operating model, live dashboard content,
and pasted freeform Hebrew instructions at once. Mixing a stable process contract with
live status makes both harder to maintain — status churns constantly while process should
be stable. No `GSD.md` existed in the working tree, git history, other branches, or stash,
so this was a bootstrap, not a split.

Rationale recorded: a process doc that never carries live data stays trustworthy; a
dashboard that owns all volatile state gives one obvious place to check "where are we";
the `gsd/` folders make the loop auditable since each stage leaves a dated artifact.

Follow-ups: add the first `gsd/verifications/` note once the MongoDB seed is validated
live; keep `STATUS.md` current as branches merge into `main`.

## Topic: coordinator review plan status

- **source:** `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, prec 2)

The plan self-declares: **"Do not run the individual repo reviews yet — this plan is the
deliverable."** Its definition of done is unmet by design:

- [ ] CI-workflow verification split (Daniel reports / Sean decides) confirmed with the team
- [ ] R1–R10 repo-feedback reports created under `gsd/repo-feedback/`
- [ ] `STATUS.md` refreshed per §5 with owner tags preserved
- [ ] No code/Terraform/Helm/secret changes made during reviews

Risk-first execution order: security sweep (CI/CD auth) → infrastructure → deployments →
backend image repos → frontend/domain → reference parity → consolidation.

**Note:** the OIDC security sweep that ranked first in this order has since been resolved
per `STATUS.md`, which changes the risk-first calculus if the plan is ever executed.

## Topic: legacy Stage 3 layout (README, largely stale)

- **source:** `README.md` (DOC) — see `INGEST-CONFLICTS.md` WARNING 1

Describes a starter `k8s/` tree where "every file under this directory contains inline
`TODO` comments instead of working resource definitions": `namespace.yaml`,
`secrets/app-secrets.yaml`, `configmaps/{auth,cart,order,payment}-config.yaml`,
per-service `{deployment,service}.yaml` directories, and `mongodb/{values,init-configmap}.yaml`.
Notes that catalog-service needs no non-secret config. Apply order was raw `kubectl apply`
per directory plus a standalone `helm upgrade --install mongodb bitnami/mongodb`.

None of this matches the current Helm-umbrella + Argo CD structure. The live constraints
this document still carries are extracted to `constraints.md` C-7, C-8, C-10 and
`decisions.md` D-8.
