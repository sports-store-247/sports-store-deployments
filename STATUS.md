# STATUS — Sports Store Deployments

Live project dashboard. Process rules live in [`GSD.md`](./GSD.md); this file tracks
**current state** only.

_Last updated: 2026-08-03 (post-merge full risk scan — see
[risk scan](./gsd/verifications/2026-08-03-post-merge-full-risk-scan.md) /
[feedback](./gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md);
prior [render report](./gsd/verifications/2026-08-03-helm-template-render.md))_

---

## Snapshot

| Field | Value |
|-------|-------|
| Stage | Stage 3+ — Helm umbrella + Argo CD GitOps + ESO restructure landed on `main` |
| Namespace (target) | `sports-store` |
| Active branch | `gsd/post-merge-full-risk-scan` (in sync with `main`) |
| Default branch | `main` (PR-gated, 1 approval required) |
| Helm chart | `helm/sports-store` (parent chart; Bitnami MongoDB dependency) |
| GitOps | `argocd-app.yaml` (AppProject + Application, automated sync) |
| Public domain | https://sportsstore.seansite.org/ (frontend reachable — status signal only) |

---

## Ownership & scope

- **David Rubin** — deployments / Helm / GitOps / docs / deployment readiness.
- **Sean** — infrastructure / AWS / Terraform / EKS / ALB / ECR / CI cloud-auth decisions.
- **Maxim** — review / coordination / repo hygiene / validation feedback (reports blockers).
- **Daniel Rusman** — service/application behavior / API contracts / service env requirements.
- Frontend/domain reachability is a **project status signal**; full E2E is **cross-team**.

---

## Verification state

Two distinct levels of "working" are tracked separately. Do not conflate them.

| Level | Meaning | Current |
|-------|---------|---------|
| Reachable frontend / domain | Public URL loads and serves the app UI | ✅ status signal (Sean) |
| Full E2E verified | Frontend → gateway → each API → data layer proven end-to-end | ❌ not verified |

No API/demo-flow evidence has been collected. **E2E remains unverified.**

---

## Org delta — 2026-08-03

Full `git fetch --prune` sweep across all 10 repos. Highlights:

**Resolved / advanced**

- ✅ **OIDC regression RESOLVED.** All 7 service repos merged
  `fix: revert to OIDC role-to-assume for AWS credentials`. Cross-team security
  blocker closed (Sean/CI decision).
- ✅ **`:latest` fixed in the service repos' CI** (image build side).
- ✅ **Required extension DECLARED** — `sports-store-infrastructure` #6. Implementation
  not yet verified (cross-team).
- ✅ **Deployments restructure landed on `main`** (#17/#18): Argo CD AppProject +
  Application, External Secrets Operator (`externalsecret.yaml`/`secretstore.yaml`/
  `serviceaccount-eso.yaml`, replacing the deleted empty `secret.yaml`),
  `environments/production/{values,images}.yaml`, `ingress.yaml`, `servicemonitor.yaml`,
  `values-aws.yaml`. This **supersedes** the old "app-secrets empty `stringData`" item.

**Resolved since last scan (verified in post-merge render)**

- ✅ **F1 — image tags.** All 6 app images now `0.1.0-<7char-hash>` (no `latest`).
- ✅ **F3 — ingress routing.** Backend → Service `gateway`:80 in `sports-store` (merged).
- ✅ **F4 — ServiceMonitors now render** (6 emitted). But selectors don't match — see R1.

**Open — David-owned (deployment layer) — VERIFIED via post-merge render**

- 🔴 **R1 — Metrics not scraped.** ServiceMonitor selectors want
  `app.kubernetes.io/name: <service>`, but Services carry `app.kubernetes.io/name:
  sports-store` (shared helper). No Service matches → Prometheus scrapes nothing.
- 🔴 **R2 — MongoDB has no persistence.** `datadir` is `emptyDir` on a Deployment (no PVC).
  Data does not survive restart/upgrade/rollback/uninstall — **brief violation**.
- 🟠 **R4 — `mongo-init` ConfigMap renders with blank namespace** (missing
  `.Values.namespace.name`); wrong-namespace on a raw `kubectl apply` without `-n`.
- 🟠 **F2 — Argo CD Application name = `cloudcart`** (duplicate `name:` in `argocd-app.yaml`).
- 🟠 **F6 — Frontend not chart-managed** (no Deployment/Service renders). Confirm intent.

_Evidence: lint clean, `helm template --namespace sports-store` exit 0, 1519 lines; see
[risk scan](./gsd/verifications/2026-08-03-post-merge-full-risk-scan.md)._

**Open — other owners (track, don't fix)**

- 🔴 **R3 (cross-team blocker) — Sean:** `app-secrets`/Mongo URIs come from AWS Secrets
  Manager `sports-store/production` via ESO (IRSA `sports-store-external-secrets-role`,
  `us-east-1`). If the ESO operator, secret, properties, or IRSA are missing → pods not
  ready → ALB 503 → demo fails. `*_MONGO_URI` values must resolve `sports-store-mongodb:27017`.
- Sean: ALB controller install; EBS StorageClass for R2; required-extension implementation.
- Daniel: R5 `/metrics` endpoints on service `http` ports; `fix/ci-instrumentator` PRs.

---

## Recent activity

- deployments `main`: #18 `fix/deployments-restructure`, #17 `fix/gateway-service-name`,
  #16 `docs/helm-secret-bootstrap`.
- infrastructure `main`: #6 declare extension; #5 ALB naming; Argo CD/Grafana ingress domains.
- all 7 service repos: `fix/oidc-regression` merged.

---

## In progress

- **Org delta monitoring** (this note set) — cross-repo fetch, brief-compliance lens,
  and the David Action Queue in
  [org-delta-summary](./gsd/repo-feedback/2026-08-03-org-delta-summary.md).

---

## Next up (David's scope)

- [ ] Plan R1 (ServiceMonitor label match) and R2 (MongoDB persistence) as
      `gsd/instructions/` notes, each on its own future branch.
- [ ] Plan R4 (`mongo-init` namespace) and F2 (Argo CD app name) corrections.
- [ ] Confirm frontend intent (F6) with the team.
- [ ] Get Secrets Manager content + StorageClass answers from Sean (R2/R3).

---

## Known issues / watch

- 🔴 R1 ServiceMonitor selector ≠ Service labels → metrics not scraped (David) — verified.
- 🔴 R2 MongoDB `emptyDir` (no PVC) → data loss on upgrade/uninstall (David) — verified, brief violation.
- 🔴 R3 ESO-sourced secrets depend on Sean's Secrets Manager + IRSA (cross-team blocker).
- 🟠 R4 `mongo-init` blank namespace; F2 Argo CD app `cloudcart`; F6 frontend not chart-managed.
- Domain reachability ≠ E2E verified. Keep the two separate in all reports.
- Secrets must stay reference-only in git. Any leaked value is an immediate fix.
