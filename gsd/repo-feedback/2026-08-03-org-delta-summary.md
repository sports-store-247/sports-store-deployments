# Org Delta Summary — 2026-08-03

_Companion to [`../research/2026-08-03-org-delta-monitor.md`](../research/2026-08-03-org-delta-monitor.md).
Documentation-only. No fixes applied._

## What changed since the last STATUS snapshot

1. **OIDC regression — RESOLVED.** All 7 service repos merged
   `fix: revert to OIDC role-to-assume for AWS credentials`. The cross-team security
   blocker is closed. (Owner of decision: **Sean**.)
2. **Required extension — DECLARED.** `sports-store-infrastructure` #6
   `docs: formally declare the required extension`. Implementation still unverified.
   (Owner: **Sean/infra**; implementation is cross-team.)
3. **Deployments restructure — LANDED on `main`** (#17, #18). Added Argo CD
   AppProject+Application (`argocd-app.yaml`), External Secrets Operator templates
   (`externalsecret.yaml`, `secretstore.yaml`, `serviceaccount-eso.yaml`), deleted the
   old empty `secret.yaml`, added `environments/production/{values,images}.yaml`,
   `ingress.yaml`, `servicemonitor.yaml`, `values-aws.yaml`. (Owner: **David**.)
4. **New open CI PRs** on 5 backends: `fix/ci-instrumentator`
   "Fix CI Test Failure (Instrumentator bug)". (Owner: **Daniel/service**.)

## Findings by classification

| # | Finding | Class | Impacts David's deploy work? |
|---|---------|-------|------------------------------|
| F1 | `latest`/`0.1.0-latest` image tags in `values.yaml` + `environments/production/images.yaml` (brief violation) | **David-owned** | **YES** |
| F2 | Argo CD Application name resolves to `cloudcart` (duplicate `name:` key) | **David-owned** | **YES** |
| F3 | `ingress.yaml` duplicate `service.name` key | **David-owned** | **YES** |
| F4 | ServiceMonitor uses `.Values.microservices` vs `.Values.services` elsewhere (possible silent no-op) | **David-owned** | **YES** |
| F5 | Local branch behind restructure; ESO supersedes old "app-secrets empty" premise | **David-owned** | **YES** |
| D1 | OIDC reverted to role-to-assume in all 7 repos | Cross-team blocker → **resolved (Sean)** | Indirect |
| D2 | Required extension declared, not yet verified implemented | Cross-team (**Sean** declare) | Indirect |
| D3 | `fix/ci-instrumentator` open on 5 backends | **Daniel/service** | Indirect (image builds) |
| D4 | ALB fronting gateway; observability stack (kube-prom/Loki/Alloy/dashboards/alerts) | **Sean/infra** | Dependency |
| D5 | `sports-store-local` stale reference repo | **Informational only** | No |

---

## DAVID ACTION QUEUE

### 1. Immediate (David-owned, no external dependency)
- [ ] **Refresh local from `main`** — merge/rebase `docs/helm-secret-bootstrap` onto the
      post-restructure `main` (#17/#18) before any further deployment work (F5). Commit
      the pending `STATUS.md`/`GSD.md`/coordinator docs on the current base first.
- [ ] **Document F2** — Argo CD Application `name: cloudcart` duplicate-key defect; plan
      a one-line correction to `sports-store` on a dedicated branch (fix later, not now).
- [ ] **Document F3** — `ingress.yaml` duplicate `service.name` key; note intended name.
- [ ] **Verify F4** — run `helm template` to confirm whether ServiceMonitor renders
      (values-key mismatch), and record evidence under `gsd/verifications/`.

### 2. Blocked by team dependencies (David-owned, needs input first)
- [ ] **F1 tag pinning** — replace `latest`/`0.1.0-latest` in `images.yaml`/`values.yaml`
      with real `<semver>-<7char-hash>` tags. **Blocked on** the actual tags CI pushes to
      ECR (need Sean/Daniel to confirm the tag scheme and current pushed tags).
- [ ] **ESO wiring verification** — confirm `externalsecret.yaml`/`secretstore.yaml`
      resolve against a real backend. **Blocked on** Sean (AWS Secrets Manager / IRSA /
      SecretStore backend + IAM).
- [ ] **Argo CD Synced+Healthy evidence** — **blocked on** a live EKS cluster (Sean).

### 3. Questions for the team
- **Sean:** What is the canonical ECR tag scheme and the current pushed tag per service,
  so `environments/production/images.yaml` can be pinned (F1)? Is `0.1.0-latest` a
  deliberate placeholder or an oversight?
- **Sean:** Is the ESO `SecretStore` backend (AWS Secrets Manager + IRSA role) provisioned,
  and what are the exact secret keys/paths the `ExternalSecret` should reference?
- **Sean:** Is the AWS Load Balancer Controller installed on the cluster so the gateway
  `ingress.yaml` (ALB) actually provisions?
- **Maxim:** Can you confirm the ownership split for CI-workflow *content* review
  (Daniel reports / Sean decides) so the coordinator plan's open assumption is closed?
- **Daniel:** Does `fix/ci-instrumentator` change published image tags or the metrics
  `/metrics` endpoint the ServiceMonitor scrapes?

### 4. Track but do NOT fix (other owners)
- OIDC revert (D1) — resolved, Sean/CI. Track only.
- Required extension implementation (D2) — Sean/infra + cross-team.
- `fix/ci-instrumentator` PRs (D3) — Daniel/service.
- ALB controller + full observability stack (D4) — Sean/infra.
- `sports-store-local` drift (D5) — informational.

### 5. Recommended next safe Claude prompt
> "Documentation + verification only. In `sports-store-deployments`, run `helm template`
> against `helm/sports-store` with `environments/production/values.yaml` and
> `images.yaml`, and record the rendered output as evidence in
> `gsd/verifications/2026-08-03-helm-template-render.md`. Confirm: (a) whether the
> ServiceMonitor block renders (F4 value-key mismatch), (b) the exact image tags that
> resolve (F1), and (c) that only the gateway gets an Ingress. Do NOT edit Helm,
> Terraform, or app code. Do NOT commit, push, or open a PR. Then update STATUS.md
> Next-up with the verified findings."

---

## Guardrails honored
Documentation/reporting only. No commits, pushes, PRs, branches, or edits to
Helm/Terraform/application code. No secret values added. E2E **not** claimed —
domain reachability is a status signal only.
