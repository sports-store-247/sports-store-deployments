# STATUS — Sports Store Deployments

Live project dashboard. Process rules live in [`GSD.md`](./GSD.md); this file tracks
**current state** only.

_Last updated: 2026-08-03 (org delta check — see
[org-delta-monitor](./gsd/research/2026-08-03-org-delta-monitor.md) /
[summary](./gsd/repo-feedback/2026-08-03-org-delta-summary.md))_

---

## Snapshot

| Field | Value |
|-------|-------|
| Stage | Stage 3+ — Helm umbrella + Argo CD GitOps + ESO restructure landed on `main` |
| Namespace (target) | `sports-store` |
| Active branch | `docs/helm-secret-bootstrap` (⚠️ behind `main`; #17/#18 not merged in locally) |
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

**Open — David-owned (deployment layer)**

- 🔴 **F1 — `latest` still deployed.** `helm/sports-store/values.yaml` (6×) and
  `environments/production/images.yaml` (`0.1.0-latest`, all 7 services) resolve to
  `latest`-style tags. Brief requires `<semver>-<7char-hash>` and no `latest`. The
  service-repo CI fix did **not** propagate to the deployments chart. Blocked on the
  real pushed tags (Sean/Daniel).
- 🟠 **F2 — Argo CD Application name = `cloudcart`.** Duplicate `name:` key in
  `argocd-app.yaml` (last wins) revives the `cloudcart` vs `sports-store` mismatch at
  the GitOps layer (destination namespace is correctly `sports-store`).
- 🟠 **F3 — `ingress.yaml` duplicate `service.name` key.**
- 🟠 **F4 — ServiceMonitor value-key mismatch** (`.Values.microservices` vs
  `.Values.services`); may render nothing — verify via `helm template`.
- 🟠 **F5 — local branch behind restructure**; refresh before further deployment work.

**Open — other owners (track, don't fix)**

- Sean: ESO `SecretStore` backend (AWS Secrets Manager + IRSA), ALB controller, and the
  full observability stack (kube-prometheus-stack / Loki / Alloy / dashboards / alerts).
- Sean/team: required-extension **implementation** evidence.
- Daniel: `fix/ci-instrumentator` open PRs on 5 backends.

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

- [ ] Refresh `docs/helm-secret-bootstrap` onto post-restructure `main` (F5).
- [ ] `helm template` verification note under `gsd/verifications/` — check F4 render,
      F1 resolved tags, and gateway-only Ingress.
- [ ] Plan corrections for F2 (Argo CD app name) and F3 (ingress name) on their own branches.
- [ ] Get canonical ECR tag scheme from Sean to pin F1.

---

## Known issues / watch

- 🔴 F1 `latest`/`0.1.0-latest` deployed image tags — brief violation at the deploy layer.
- 🟠 F2 Argo CD Application name `cloudcart` (should be `sports-store`).
- 🟠 F3/F4 duplicate-key and ServiceMonitor value-key defects (verify before fixing).
- Domain reachability ≠ E2E verified. Keep the two separate in all reports.
- ESO now owns app secrets; wiring depends on Sean's AWS Secrets Manager + IRSA backend.
- Secrets must stay reference-only in git. Any leaked value is an immediate fix.
