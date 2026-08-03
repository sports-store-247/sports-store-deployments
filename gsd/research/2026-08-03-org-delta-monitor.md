# Org Delta Monitor — 2026-08-03

_Role: GSD Org Delta Monitor · Reporting repo: `sports-store-deployments` · Documentation-only._

Delta check across the organization since the last `STATUS.md` snapshot (dated
2026-08-03, pre-restructure). `git fetch origin --prune` was run in every repo.
No commits, pushes, PRs, or code/Helm/Terraform edits were made.

**Headline:** the org moved substantially since the last snapshot. The **OIDC
regression is resolved** across all 7 service repos, the **required extension was
declared** in infrastructure, and a **large deployment-layer restructure** landed on
`sports-store-deployments` `main` (Argo CD app, External Secrets, environment image
files, ingress, ServiceMonitor). New David-owned defects were introduced by that
restructure.

---

## Per-repo delta

### sports-store-infrastructure — owner: Sean
- Local branch: `main`
- origin/main last 5:
  - `89b426f docs: formally declare the required extension (#6)`
  - `5974efe Merge PR #5 fix/sportsstore-alb-naming`
  - `8a0dfef fix: move grafana to root path of dedicated domain`
  - `f7f8c18 fix: remove rootpath from argocd`
  - `74e121e fix: change argocd ingress to use dedicated argocd.seansite.org domain`
- Open PRs: none
- Delta vs snapshot: **Required extension now declared** (#6). ALB naming fixed;
  Grafana/Argo CD ingress moved to dedicated domains.
- Classification: **Sean-owned** (infra/Terraform/observability). Informational to David.

### sports-store-deployments — owner: David
- Local branch: `docs/helm-secret-bootstrap` (behind origin/main — see below)
- origin/main last 5:
  - `049d375 Merge PR #18 fix/deployments-restructure`
  - `ca84c97 Merge PR #17 fix/gateway-service-name`
  - `78aec85 Merge branch main into fix/deployments-restructure`
  - `15dd591 Merge branch main into fix/gateway-service-name`
  - `c7a129c Merge PR #16 docs/helm-secret-bootstrap`
- Open PRs: none
- Delta vs snapshot (files added/changed on main by #17+#18):
  - `A argocd-app.yaml` — Argo CD AppProject + Application
  - `A helm/sports-store/environments/production/images.yaml` + `values.yaml`
  - `A templates/externalsecret.yaml`, `secretstore.yaml`, `serviceaccount-eso.yaml`
  - `D templates/secret.yaml` — **old app-secrets Secret template removed**
  - `A templates/ingress.yaml`, `templates/servicemonitor.yaml`
  - `A values-aws.yaml`, `M values.yaml`
- Classification: **David-owned** deployment/Helm/GitOps. **Directly impacts David.**

### sports-store-local — reference only
- Local branch: `main`; origin/main last activity `2026-07-30` (PR #2)
- Open PRs: none
- Delta: none relevant. Reference/scaffold repo; brief graded focus is Helm+EKS, not local.
- Classification: **Informational only.**

### Service repos (auth, catalog, cart, order, payment, gateway, frontend) — owner: Daniel; CI auth decision: Sean
- Local branch: `main` in all
- origin/main pattern (identical across all 7):
  - `Merge PR #<n> fix/oidc-regression`
  - `fix: revert to OIDC role-to-assume for AWS credentials`
  - `Merge PR fix/ci-secrets-ecr`
  - `chore: full pass remediation across brief milestones`
  - `Switch to GitHub Secrets for reliable ECR authentication` (2026-08-02, the regression)
- Open PRs: `fix/ci-instrumentator` — "Fix CI Test Failure (Instrumentator bug)":
  auth #9, catalog #9, cart #9, order #9, payment #8. Gateway/frontend: none.
- Delta vs snapshot: **OIDC regression reverted/fixed** in every service repo. A new
  open CI test-failure fix (Instrumentator) is in flight for 5 backends.
- Classification: **Daniel/service-owned** (CI test fix); OIDC **cross-team blocker now
  resolved** (Sean/CI decision). Informational to David.

---

## Deployment-layer findings (David-owned, evidence-backed)

### F1 — `latest` used for deployable images (brief violation) 🔴
- Evidence:
  - `helm/sports-store/values.yaml` lines 16, 42, 65, 91, 121, 147: `tag: latest`
  - `helm/sports-store/environments/production/images.yaml`: all 7 services `tag: "0.1.0-latest"`
- Brief requires `<semver>-<7-char-git-hash>` and **no `latest` anywhere for deployable images**.
  `0.1.0-latest` is not a git-hash tag and contains `latest`.
- **Contradicts** the prior STATUS.md claim "✅ `:latest` fixed across all 7 repos" — the
  fix held in the service *repos'* CI, but the **deployments chart still deploys `latest`**.
- Owner: **David** (deployment layer). Needs the real pushed tag values from CI/ECR
  (input from Sean/Daniel) to pin correctly.

### F2 — Argo CD Application name resolves to `cloudcart` 🟠
- Evidence: `argocd-app.yaml` Application `metadata` has duplicate keys —
  `name: sports-store` then `name: cloudcart`; YAML last-key-wins → app name = `cloudcart`.
- Revives the `cloudcart` vs `sports-store` naming mismatch at the GitOps layer.
  (Destination namespace is correctly `sports-store`; the Application *name* is wrong.)
- Owner: **David** (GitOps config in deployments repo).

### F3 — `ingress.yaml` duplicate `service.name` key 🟠
- Evidence: backend block has `name: gateway` then `name: {{ $.Release.Name }}-gateway`
  (last wins). Same duplicate-key sloppiness pattern as F2.
- Owner: **David** (Helm template). Verify the intended Service name before any fix.

### F4 — ServiceMonitor value-key mismatch (to verify) 🟠
- Evidence: `servicemonitor.yaml` ranges over `.Values.microservices`, while
  `images.yaml`/`ingress.yaml` use `.Values.services`. If `microservices` is undefined,
  the ServiceMonitor block renders nothing (silent observability gap).
- Owner: **David** (Helm). Confirm via `helm template` before acting. Not fixed here.

### F5 — Local branch is behind the restructure 🟠
- `docs/helm-secret-bootstrap` (local) predates #17/#18. Working tree also holds
  uncommitted `STATUS.md`, `GSD.md`, and the coordinator plan on that stale base.
- The ESO restructure **supersedes** the old "app-secrets renders empty `stringData`"
  premise — `secret.yaml` was deleted and replaced by `externalsecret.yaml` +
  `secretstore.yaml`. David should refresh from `main` before further deployment work.
- Owner: **David**.

---

## Brief compliance lens (evidence-based; nothing marked complete without evidence)

| Brief requirement | State | Evidence / note |
|-------------------|-------|-----------------|
| Polyrepo structure exists | ✅ | 10 repos present under org root |
| No direct pushes to main; PR workflow | ✅ | All recent `main` commits are PR merges |
| deployments owns k8s/Helm/Argo CD/observability config | ✅ | `argocd-app.yaml`, `helm/`, `servicemonitor.yaml` in repo |
| infrastructure owns Terraform | ✅ (scope) | Sean's repo; not file-audited here |
| Graded focus Helm + EKS (not local) | ℹ️ | `sports-store-local` stale (2026-07-30), reference only |
| Parent chart under `helm/sports-store` | ✅ | `helm/sports-store/Chart.yaml` |
| Bitnami MongoDB as Helm dependency | ✅ | `Chart.yaml` deps + `Chart.lock` + `charts/mongodb-16.5.20.tgz` |
| Services via templates/range/helpers | ✅ | `_helpers.tpl`, `deployments.yaml`, `services.yaml` (range-based) |
| install/upgrade/rollback/uninstall | ❔ not verified | No `helm` lifecycle run this task |
| MongoDB persistence survives lifecycle | ❔ not verified | Needs evidence |
| ECR tags `<semver>-<7hash>` | ❌ | F1 — `latest`/`0.1.0-latest` at deploy layer |
| `latest` not used anywhere | ❌ | F1 — `values.yaml` + `images.yaml` |
| CI AWS auth OIDC, not static keys | ✅ resolved | `fix: revert to OIDC role-to-assume` merged in all 7 repos |
| PR workflows must not publish/touch cluster | ❔ not verified | Service-repo workflow YAML not audited (Daniel/Sean) |
| Main workflows may build/push to ECR | ❔ not verified | Not audited |
| GitOps via Argo CD (not manual) | ✅ | `argocd-app.yaml` `syncPolicy.automated` (prune+selfHeal) |
| Argo CD AppProject + Application | ✅ | Both present in `argocd-app.yaml` |
| Argo CD watches deployments `main` | ✅ | `repoURL` deployments, `targetRevision: main` |
| Per-service image config in env files | ✅ (with F1) | `environments/production/images.yaml` |
| Gateway only external entrypoint | ✅ | Only `gateway` has an ingress template |
| ALB fronts gateway | ◐ partial | Ingress present; `className`/annotations values-driven; ALB controller = infra (Sean) |
| Observability stack (kube-prom, Loki/Alloy, dashboards, alerts, ServiceMonitors) | ◐ partial | ServiceMonitor in deployments (F4 caveat); stack itself infra (Sean) |
| Required extension declared AND implemented | ◐ | Declared ✅ (infra #6); implementation ❌ not verified |
| Argo CD apps Synced + Healthy at demo | ❔ not verified | No cluster access |

Legend: ✅ met · ❌ violated · ◐ partial · ❔ not verified · ℹ️ informational

---

## Verification boundary

- Frontend/domain reachability (`https://sportsstore.seansite.org/`) remains a
  **project status signal only** — **not** full E2E. No API/demo-flow evidence was
  collected this task, so **E2E stays unverified**.
