# Deployments — Post-merge feedback (2026-08-03)

_Companion to [`../verifications/2026-08-03-post-merge-full-risk-scan.md`](../verifications/2026-08-03-post-merge-full-risk-scan.md).
Documentation only. No fixes applied._

## Post-merge health: green on structure, two deploy-blocking gaps

The merged chart is structurally solid — lint clean, namespace-aware render exit 0, F3
routing fixed, F1 image tags now `0.1.0-<7char-hash>` (no `latest`), F4 ServiceMonitors
now emit, ESO restructure renders with consistent internal wiring. Two verified issues
would still break a live deploy/demo, plus one runtime dependency chain owned by Sean.

## Findings by classification

| # | Finding | Severity | Owner | Failure mode |
|---|---------|----------|-------|--------------|
| R1 | ServiceMonitor selector (`app.kubernetes.io/name: <svc>`) ≠ Service label (`…/name: sports-store`) | 🔴 | **David** | Metrics not scraped |
| R2 | MongoDB `datadir` is `emptyDir` on a Deployment; no PVC | 🔴 | **David** | Mongo data loss; brief violation |
| R3 | `app-secrets`/Mongo URIs sourced from AWS Secrets Manager `sports-store/production` via ESO | 🔴 | **Sean (runtime) — cross-team blocker** | Missing secrets → pods not ready → ALB 503 |
| R4 | `mongo-init` ConfigMap renders with blank namespace | 🟠 | **David** | Wrong-namespace on raw apply |
| R5 | `/metrics` endpoint must exist on service `http` port | 🟠 | **Daniel** | Metrics not scraped (secondary) |
| R6 | Mongo root & user passwords map to one property | ℹ️ | **Sean** | Informational |
| R7 | Argo CD Application named `cloudcart` (F2, `argocd-app.yaml`) | ℹ️ | **David (separate task)** | Cosmetic naming |
| — | Frontend not chart-managed (no Deployment/Service) | ℹ️ | **David/team** | Confirm intent |

## Verified good (no action)
- Lint clean; render exit 0; 32 resources, all `sports-store` except R4.
- Ingress → Service `gateway`:80 in `sports-store` (F3 holds).
- Image tags `0.1.0-<hash>`, no `latest` (F1 resolved).
- ESO target Secret `app-secrets` == app `secretKeyRef.name` (wiring consistent).
- SecretStore: AWS SecretsManager, `us-east-1`, IRSA `app-secrets-sa` →
  `sports-store-external-secrets-role`.

---

## DAVID ACTION QUEUE

### Immediate (David-owned, no external dependency)
1. **R1 — ServiceMonitor label match.** Plan a fix so the ServiceMonitor selector and the
   Service labels agree (either add `app.kubernetes.io/name: <service>` to the Service
   labels, or change the selector to `app: <service>` which the Services already carry).
   Verify with `helm template` that selector labels exist on the target Service.
2. **R2 — MongoDB persistence.** Plan enabling Bitnami MongoDB persistence
   (`mongodb.persistence.enabled=true` + storageClass/size) so data survives
   upgrade/rollback/uninstall, per the brief. (Values change — its own branch, not now.)
3. **R4 — `mongo-init` namespace.** Add `namespace: {{ .Values.namespace.name }}` to the
   `mongo-init` ConfigMap for consistency with the rest of the chart.
4. Record the R1/R2 fix plans as `gsd/instructions/` notes before editing Helm.

### Blocked by team dependencies (David-owned, needs input)
5. **R2 storage class** — persistence needs an EKS storage class / EBS CSI driver
   available. Confirm with Sean before pinning `storageClass`.
6. **R3 secret values** — cannot pin/verify `*_MONGO_URI` without the Secrets Manager
   content. Blocked on Sean.

### Questions for the team
- **Sean:** Is the ESO operator installed, is Secrets Manager `sports-store/production`
  populated (JWT_SECRET + 5 `*_MONGO_URI` + MONGO_ROOT_PASSWORD), and is the IRSA role
  `sports-store-external-secrets-role` trust-scoped to `app-secrets-sa`/`sports-store`?
- **Sean:** Do the `*_MONGO_URI` values point to `sports-store-mongodb:27017` with the
  correct auth db and credentials? Is an EBS-backed StorageClass available for R2?
- **Sean:** Is the AWS Load Balancer Controller installed so the gateway ALB provisions
  and target health can pass?
- **Daniel:** Do the service images expose `/metrics` on their `http` port? Does
  `fix/ci-instrumentator` change that endpoint?

### Track but do NOT fix (other owners)
- R3 secret/IRSA/ESO-operator provisioning — Sean.
- R5 `/metrics` endpoints + `fix/ci-instrumentator` — Daniel.
- R6 password-property design — Sean.

### Recommended next safe action
> "Documentation + verification only, in `sports-store-deployments`. Write a
> `gsd/instructions/` plan for R1 (ServiceMonitor label match) and R2 (MongoDB
> persistence), each on its own future branch, then run `helm template` to prove the
> intended selector/label alignment renders. Do NOT edit Helm/Terraform/app/CI. Do NOT
> commit, push, or open a PR. Update STATUS.md Next-up with the plan."

## Guardrails honored
Documentation/reporting only. No commits, pushes, PRs, or edits to
Helm/Terraform/app/CI/secrets. E2E not claimed — reachability is a status signal only.
