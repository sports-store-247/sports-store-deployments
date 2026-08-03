# Coordinator Plan — Repo-Level Agent Reviews

_Date: 2026-08-03 · Role: GSD Coordinator Agent · Repo of record: `sports-store-deployments`_

This is a **plan only**. No repo reviews are executed here. It defines who reviews
what, what stays untouched, where reports land, how `STATUS.md` is updated afterward,
the execution order, and finding ownership.

Grounded in [`GSD.md`](../../GSD.md) (operating model) and [`STATUS.md`](../../STATUS.md)
(current org state, incl. the OIDC regression and Helm `app-secrets` items).

> **Guardrails for every repo-agent (non-negotiable):** documentation/reporting only.
> No commits, no pushes, no PRs. Do not modify application code, Terraform, or Helm
> (unless a follow-up task explicitly authorizes it). Never add, print, or commit
> secret *values* — reference names only.

---

## Ownership model (authoritative)

| Person | Owns / supports |
|--------|-----------------|
| **David Rubin** | Deployments, Helm, GitOps, documentation, deployment readiness |
| **Sean** | Infrastructure, AWS, Terraform, EKS, ALB, ECR, CI cloud-authentication decisions (incl. OIDC) |
| **Maxim** | Review, coordination, repo hygiene, validation feedback. **Reports** blockers; not the implementation owner of Terraform/OIDC unless explicitly confirmed |
| **Daniel Rusman** | Service/application behavior, API contracts, service env requirements |

Notes:
- **Frontend / domain reachability** (https://sportsstore.seansite.org/) is a
  **project status signal**, not any single person's exclusive ownership. Sean
  provided the update; the signal belongs to the project.
- **Full E2E validation is cross-team** (deploy wiring + services + infra + frontend).

---

## 1. Repos that need review

| # | Repo | Primary owner | Why it's in scope |
|---|------|---------------|-------------------|
| R1 | `sports-store-deployments` (this repo) | David | Helm umbrella, k8s manifests, GitOps entry, docs, deployment readiness |
| R2 | `sports-store-infrastructure` | Sean | Terraform, AWS/EKS/ALB/ECR, Argo CD hosting, IAM/OIDC, observability |
| R3 | `auth-service` (image repo) | Daniel | Service behavior, API contract, env requirements; CI/CD workflow |
| R4 | `catalog-service` (image repo) | Daniel | Service behavior, API contract, env requirements; CI/CD workflow |
| R5 | `cart-service` (image repo) | Daniel | Service behavior, API contract, env requirements; CI/CD workflow |
| R6 | `order-service` (image repo) | Daniel | Service behavior, API contract, env requirements; CI/CD workflow |
| R7 | `payment-service` (image repo) | Daniel | Service behavior, API contract, env requirements; CI/CD workflow |
| R8 | `gateway` (image repo) | Daniel (service) | Reverse proxy + CI/CD workflow; fronts the public domain signal |
| R9 | Frontend / storefront (image repo) | Daniel (service) | Serves https://sportsstore.seansite.org/ (Stryda Athletics) — reachability is a project status signal |
| R10 | `sports-store-local` | — (reference only) | **Reference repo** (local/dev compose or scaffold). Review for drift/parity; **not an active deployment-owner repo** |

R3–R9 are the **7 image repositories** referenced in the org sweep. R10 is included
as a **reference review target only** — it is not a deployment-owning repo and no
deployment decisions are driven from it.

> **CI cloud-auth note:** decisions about OIDC vs static keys in any repo's CI/CD are
> **Sean's** (CI cloud-authentication decisions). Service-repo agents (Daniel) and the
> reviewer (Maxim) **report** what they observe in those workflows; they do not own
> the auth-model decision.

> **Assumption to confirm:** the exact split of who verifies CI workflow *content*
> inside each image repo (Daniel as service owner vs. Sean as auth-decision owner)
> should be confirmed with the team before execution. Reporting responsibility is
> shared; the auth **decision** sits with Sean.

---

## 2. What each repo-agent should check

### R1 — `sports-store-deployments` (David)
- Helm `app-secrets` renders with **empty `stringData`** (reproduce via `helm template`) — record only.
- GitOps structure: presence/absence of Argo CD `AppProject`, `environments/`, per-service image files.
- Namespace consistency: everything targets `sports-store` (flag any `cloudcart` leftovers).
- Manifest hygiene: gateway is the only externally exposed Service; secrets are reference-only.
- Deployment readiness: apply-order and dependency assumptions still hold.

### R2 — `sports-store-infrastructure` (Sean)
- **CI cloud auth:** OIDC vs static keys for AWS (should be OIDC `role-to-assume`).
  Sean owns this decision; the agent documents current state.
- Terraform naming leftovers: `FraudstersList` / `FifaApp` in `argocd.tf`, `prometheus.tf`,
  `pod-identity.tf`, `secrets.tf`, `tfc-oidc.tf`.
- AWS/EKS/ALB/ECR wiring; Argo CD hosting location (deployments vs infrastructure).
- Observability: Alertmanager enabled state, Grafana auth configuration visibility.

### R3–R8 — backend image repos (Daniel; Sean owns any auth-model decision)
- **CI/CD push-to-ECR auth:** document whether OIDC federation is used; flag any use of
  `secrets.AWS_ACCESS_KEY_ID` / `secrets.AWS_SECRET_ACCESS_KEY` (static keys).
  Report the finding; the auth-model decision belongs to Sean.
- Service behavior / API contract / env requirements (Daniel's ownership).
- Image tagging: confirm the `:latest`-tag fix holds (immutable/pinned tags).
- Dockerfile / build config sanity (read-only observation, no edits).

### R9 — frontend / storefront (Daniel service; reachability = project signal)
- Domain reachability: https://sportsstore.seansite.org/ loads and renders Stryda Athletics.
  Document as a **project status signal**, not one person's ownership.
- Same CI/CD OIDC and `:latest` checks as the other image repos.
- **Explicitly scope as frontend/gateway/domain reachability only** — not E2E API validation.

### R10 — `sports-store-local` (reference only)
- Parity/drift check against the active deployment repos (image names, env keys, namespace).
- Flag anything stale that could mislead contributors; **no ownership actions**.
- Purely informational — findings feed awareness, not deployment decisions.

---

## 3. What each repo-agent must NOT touch

Applies to **all** agents:

- ❌ No commits, pushes, or PRs.
- ❌ No edits to application/service code.
- ❌ No edits to Terraform.
- ❌ No edits to Helm (unless a later task explicitly authorizes it).
- ❌ No adding, printing, or committing secret **values** — reference names only.
- ❌ No renaming the `sports-store` namespace.
- ❌ No cross-repo "fixes" — findings outside your lane are reported to the owner, not fixed.
- ❌ No deployment decisions driven from the `sports-store-local` reference repo.

Reviews are **read-and-report**. Remediation is a separate, owner-approved task.

---

## 4. Where each repo-agent writes its report

Central aggregation in **this** repo for coordinator visibility:

```
gsd/repo-feedback/2026-08-03-<repo-slug>-review.md
```

Examples:
- `gsd/repo-feedback/2026-08-03-deployments-review.md`
- `gsd/repo-feedback/2026-08-03-infrastructure-review.md`
- `gsd/repo-feedback/2026-08-03-auth-service-review.md`
- `gsd/repo-feedback/2026-08-03-frontend-review.md`
- `gsd/repo-feedback/2026-08-03-local-reference-review.md`

Each report must contain: repo name, date, checks run, findings (severity + owner),
evidence (command output / file:line references), and explicit "not verified" notes.
If a source repo has its own `gsd/` tree, the agent may mirror the report there, but
the copy under this repo's `gsd/repo-feedback/` is the source of truth for the coordinator.

---

## 5. How STATUS.md is updated after all reports are done

Coordinator-only step, once every R1–R10 report exists:

1. Read all `gsd/repo-feedback/2026-08-03-*-review.md` files.
2. Refresh the **Org sweep** section: move resolved items out, add any new findings,
   keep each tagged with its owner per the ownership model above.
3. Keep the **Verification state** table intact — do **not** upgrade "Reachable
   frontend / domain" to "Full E2E verified" without API-level proof. Document
   reachability as a **project status signal**.
4. Keep the **OIDC regression** as a 🔴 cross-repo security blocker. The CI
   cloud-authentication **decision** is Sean's; Maxim may **report** the blocker;
   it is **not** David's.
5. Keep Helm `app-secrets` empty render as a 🟠 David-owned deployment-layer item to
   investigate later (not fixed in a review).
6. Update **Known issues / watch** and **Next up** from the aggregated findings.
7. Bump `_Last updated_` and link the new repo-feedback reports.
8. Follow `GSD.md`: **status is written before any remediation PR**, and cross-repo /
   process-affecting actions are coordinated with the owner first.

---

## 6. Suggested order of execution (risk-first)

1. **Security sweep — CI/CD auth (OIDC):** R2 + R3–R9 workflows. Confirm the static-key
   regression scope across all repos first; it is the highest-severity open item.
   (Findings reported by service/reviewer agents; decision owner = Sean.)
2. **Infrastructure:** R2 remainder — Terraform naming, AWS/EKS/ALB/ECR, Argo CD
   hosting, observability (Sean).
3. **Deployments:** R1 — Helm `app-secrets`, GitOps structure, namespace consistency,
   deployment readiness (David).
4. **Backend image repos:** R3–R8 — `:latest` fix verification, service/API/env,
   image/Dockerfile hygiene (Daniel).
5. **Frontend / domain:** R9 — reachability confirmation as a project signal, scoped
   to non-E2E.
6. **Reference parity:** R10 — `sports-store-local` drift check (informational).
7. **Consolidation:** coordinator aggregates all reports and updates `STATUS.md` (§5).

Rationale: the OIDC regression is a live security blocker, so CI cloud auth is verified
before lower-severity structural and cosmetic items.

---

## 7. Finding ownership

| Finding area | Owner | Notes |
|--------------|-------|-------|
| Helm `app-secrets` empty `stringData` | **David** | Deployment-layer; investigate later, don't fix in review |
| GitOps structure in deployments (AppProject, environments, per-service images) | **David** | Coordinate with Sean where it overlaps Argo CD hosting/infra |
| Deployment readiness (apply order, dependencies) | **David** | Deployment-layer |
| Namespace `cloudcart` vs `sports-store` | **David** (deployments) + Sean (infra) | Align target to `sports-store` |
| `:latest` tag fix across 7 image repos | **Daniel** | Verify the fix holds |
| Service behavior / API contracts / env requirements | **Daniel** | Report only; no edits |
| CI/CD **OIDC vs static keys** (auth-model decision) | **Sean** | 🔴 cross-repo security blocker; decision owner. NOT David |
| Reporting the OIDC regression / raising the blocker | **Maxim** (may report) | Reviewer/coordinator; reports, does not own the fix decision |
| Terraform / AWS / EKS / ALB / ECR | **Sean** | Infra owner. `FraudstersList`/`FifaApp` leftovers in `.tf` files |
| Argo CD hosting location | **Sean** (infra) + David (deployments) | Decide deployments vs infrastructure together |
| Observability (Alertmanager, Grafana auth) | **Sean** | Infra owns the stack |
| Frontend / domain reachability | **Project status signal** | Sean provided the update; not exclusive ownership |
| Full E2E API validation | **Cross-team** | David (deploy wiring) + Daniel (services) + Sean (infra) + frontend |
| Repo hygiene / review coordination / validation feedback | **Maxim** | Reports and coordinates; not implementation owner |
| `sports-store-local` reference/drift | **Reference only** | No deployment ownership; informational |
| Required extension (not formally declared) | **Team** | Needs a formal decision/owner |
| Coordinator plan + STATUS aggregation + docs | **David** (this coordinator role) | Documentation/reporting only |

---

## Definition of done (for this plan)

- [ ] CI-workflow verification split (Daniel reports / Sean decides) confirmed with the team.
- [ ] R1–R10 repo-feedback reports created under `gsd/repo-feedback/`.
- [ ] `STATUS.md` refreshed per §5 with owner tags preserved.
- [ ] No code/Terraform/Helm/secret changes made during reviews.

**Do not run the individual repo reviews yet — this plan is the deliverable.**
