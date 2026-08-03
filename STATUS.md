# STATUS — Sports Store Deployments

Live project dashboard. Process rules live in [`GSD.md`](./GSD.md); this file tracks
**current state** only.

_Last updated: 2026-08-03_

---

## Snapshot

| Field | Value |
|-------|-------|
| Stage | Stage 3 — Local Kubernetes + Helm umbrella; GitOps/observability hardening |
| Namespace (target) | `sports-store` |
| Active branch | `docs/helm-secret-bootstrap` |
| Default branch | `main` (PR-gated, 1 approval required) |
| Helm chart | `helm/sports-store` (umbrella) |
| Public domain | https://sportsstore.seansite.org/ (frontend reachable — see below) |

---

## Ownership & scope

- **David** — deployments / Helm / GitOps / docs only. Does **not** own CI/CD auth,
  Terraform, or infra IAM.
- **Infra / CI owners** — AWS auth, ECR push workflows, Terraform, Argo CD hosting,
  observability stack.

Items below are tagged with the owner so scope stays unambiguous.

---

## Verification state

Two distinct levels of "working" are tracked separately. Do not conflate them.

| Level | Meaning | Current |
|-------|---------|---------|
| Reachable frontend / domain | Public URL loads and serves the app UI | ✅ confirmed (Sean) |
| Full E2E verified | Frontend → gateway → each API → data layer proven end-to-end | ❌ not verified |

**Sean's domain update:** https://sportsstore.seansite.org/ loads and renders the
Stryda Athletics storefront. This confirms **frontend / gateway / domain
reachability only**. It is **not** evidence that the backend APIs, auth, or data
flows work end-to-end — treat E2E as unverified until proven with API-level checks.

---

## Org sweep — Maxim's findings (2026-08-03)

A full organization sweep was completed. Summary of current state:

**Resolved**

- ✅ `:latest` tag issue fixed across all **7** image repositories.

**Open — security blocker (owner: infra / CI owners; NOT David)**

- 🔴 **OIDC regression (cross-repo security blocker).** CI/CD push-to-ECR workflows
  switched from an OIDC `role-to-assume` to **long-lived static AWS keys**
  (`aws-access-key-id: secrets.AWS_ACCESS_KEY_ID`,
  `aws-secret-access-key: secrets.AWS_SECRET_ACCESS_KEY`). This **violates the
  project brief**, which requires AWS auth via OIDC / short-lived federated
  credentials. Must be reverted to OIDC by the CI/infra owners. Outside David's
  deployments/docs scope — tracked here for visibility, not for David to fix.

**Open — Argo CD / GitOps gaps (owner: infra / GitOps owners; David advisory)**

- No `AppProject` defined.
- No `environments/` or per-service image files.
- Argo CD config appears to live under `sports-store-infrastructure` instead of
  `sports-store-deployments`.
- Namespace mismatch persists: `cloudcart` vs `sports-store`.

**Open — Terraform (owner: infra owners; NOT David)**

- Naming leftovers remain: `FraudstersList` / `FifaApp` references in `argocd.tf`,
  `prometheus.tf`, `pod-identity.tf`, `secrets.tf`, `tfc-oidc.tf`.

**Open — Observability (owner: infra owners)**

- Alertmanager disabled.
- Grafana auth configuration not visible.

**Open — deployment layer (owner: David, investigate later)**

- 🟠 **Helm `app-secrets` renders empty.** `helm template` still emits the
  `app-secrets` Secret with **empty `stringData`**. This is a **deployment-layer
  blocker to investigate later**, not to fix in this docs task (no Helm edits now,
  no secret values added). See [Helm secret bootstrap research](./gsd/research/2026-08-03-docs-bootstrap.md).

**Open — project brief**

- Required extension is still **not formally declared**.

---

## Recent activity

- `fix(helm): deploy mongo-init configmap to release namespace` (#14)
- `feat(helm): add mongo-init configmap to seed database` (#13)
- `fix(helm): secure mongodb auth by referencing secret` (#12)
- `fix(helm): add mongo init env vars for authentication` (#11)

---

## In progress

- **Docs bootstrap** (`docs/helm-secret-bootstrap`) — split process vs. status into
  `GSD.md` + `STATUS.md`, scaffold `gsd/` work folders, and record team status.
  See [team status research note](./gsd/research/2026-08-03-team-status-update.md).

---

## Next up (David's scope)

- [ ] Investigate Helm `app-secrets` empty `stringData` rendering (deployment-layer
      blocker; docs/analysis first, fix later on its own branch).
- [ ] Advise on Argo CD gaps that touch deployment structure (AppProject,
      environments, per-service images, namespace alignment) — coordinate with infra owners.
- [ ] First verification note under `gsd/verifications/` for the MongoDB seed.
- [ ] Confirm gateway is the only externally exposed Service.

---

## Known issues / watch

- 🔴 OIDC regression is a **cross-repo security blocker** owned by infra/CI owners.
- 🟠 Helm `app-secrets` empty rendering is a David-owned deployment-layer item to
  investigate later.
- Domain reachability ≠ E2E verified. Keep the two separate in all reports.
- Namespace target is `sports-store`; the `cloudcart` mismatch must be resolved by owners.
- Secrets must stay reference-only in git. Any leaked value is an immediate fix.
- MongoDB must be healthy before app Deployments connect cleanly.
