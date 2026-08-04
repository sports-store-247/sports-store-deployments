# Roadmap: Sports Store Deployments

## Overview

The Helm umbrella chart, the Argo CD Application, and the ESO wiring have all landed on
`main`. What remains in this repo's scope is closing the five David-owned defects the
post-merge render exposed: a stale working base, ServiceMonitor selectors that match no
Service, a `mongo-init` ConfigMap with a blank namespace, an Argo CD Application still named
`cloudcart`, and a MongoDB `datadir` on `emptyDir`. The first four are fully unblocked and
provable with `helm template` alone. The fifth is chart-side work that cannot be pinned until
Sean confirms an EBS-backed StorageClass. Each phase is one concern, one branch, one PR,
preceded by a `gsd/instructions/` note and a `STATUS.md` update. **No phase in this roadmap
achieves end-to-end verification — E2E is cross-team and out of scope here.**

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Baseline Sync** - Working base provably in sync with `main`, pending docs committed
- [ ] **Phase 2: Scrape Target Alignment** - ServiceMonitor selectors actually match the Services
- [ ] **Phase 3: Namespace Consistency** - Every rendered resource carries the target namespace
- [ ] **Phase 4: GitOps Application Identity** - Argo CD Application named `sports-store`, not `cloudcart`
- [ ] **Phase 5: MongoDB Persistence** - Data survives install/upgrade/rollback/uninstall (externally blocked)

## Standing Invariants (checked in every phase, never a phase of their own)

- **REQ-secrets-reference-only / C-3** — no secret **values** in tracked files. References
  only: `existingSecret`, env var names, placeholders.
- **C-2** — a documentation task touches no `helm/`, no Terraform, no application code. A
  change needing those gets its own non-docs branch and PR.
- **C-4** — one concern per branch and PR; `main` is PR-gated, 1 approval required.
- **C-5 / D-7** — the `gsd/instructions/` note is written and `STATUS.md` updated **before**
  the remediation PR is opened.
- **C-12 / D-6** — every verification note states its boundary explicitly. Public-URL
  reachability is a status signal and is never reported as E2E proof.
- **D-8** — namespace `sports-store` is fixed. `cloudcart` is always the defect, never the target.
- **C-1** — nothing outside David's ownership is touched; findings elsewhere are flagged to
  the owner, not fixed.

## Phase Details

### Phase 1: Baseline Sync
**Goal**: Every later change starts from a working base that is provably identical to `main`,
with all pending GSD documentation already committed on the correct base.
**Depends on**: Nothing (first phase)
**Requirements**: REQ-refresh-local-from-main
**Success Criteria** (what must be TRUE):
  1. The working branch is provably in sync with post-restructure `main` (#17/#18) — the
     check is run and its output recorded, not assumed.
  2. Pending `STATUS.md` / `GSD.md` / coordinator docs are committed on the current base
     before any chart branch is cut.
  3. If the check shows the branch already in sync — as `STATUS.md` reports for
     `gsd/post-merge-full-risk-scan` — the phase closes as **already satisfied** with that
     evidence recorded, rather than manufacturing work.
**Blockers**: None
**Process gate**: `gsd/instructions/` note + `STATUS.md` update before any PR (C-5 / D-7)
**Caveat**: `STATUS.md` (prec 1) outranks the org-delta summary that raised this item and
already reports the active branch in sync. Verify before treating this as live work.
**Plans**: TBD

### Phase 2: Scrape Target Alignment
**Goal**: Prometheus can actually select the six service Services, so the rendered
ServiceMonitors point at real targets instead of nothing.
**Depends on**: Phase 1
**Requirements**: REQ-servicemonitor-label-match
**Success Criteria** (what must be TRUE):
  1. Every ServiceMonitor's `spec.selector.matchLabels` matches labels that are actually
     present on its target Service — either `app.kubernetes.io/name: <service>` is added to
     the Service labels, **or** the selector is changed to `app: <service>`, which the
     Services already carry.
  2. `helm template` output proves the selector labels exist on the target Service, for all
     six services, with no service left unmatched.
  3. The shared `sports-store.labels` helper still renders consistent labels on every other
     resource — the fix does not fragment the label scheme.
  4. The verification note states explicitly that scraping still cannot succeed until
     `REQ-metrics-endpoints` (Daniel Rusman) lands — label match is necessary, not sufficient.
**Blockers**: None for this phase. Metrics as a whole additionally require Daniel's
`/metrics` endpoints, which are **not routable in this repo**.
**Process gate**: `gsd/instructions/` note + `STATUS.md` update before the PR; own branch
**Severity**: critical 🔴, verified via post-merge render
**Plans**: TBD

### Phase 3: Namespace Consistency
**Goal**: Every rendered resource carries the target namespace, so a raw
`kubectl apply -f` without `-n` cannot scatter the MongoDB seed ConfigMap into `default`.
**Depends on**: Phase 1
**Requirements**: REQ-mongo-init-namespace
**Success Criteria** (what must be TRUE):
  1. `templates/mongo-init-configmap.yaml` renders `namespace: {{ .Values.namespace.name }}`,
     like every other template in the chart.
  2. Namespace consistency across all rendered resources holds with **zero exceptions** —
     the render is re-checked, not just the one file.
  3. The namespace still comes from `.Values.namespace.name` with no hardcoded literal, and
     the value remains `sports-store` (D-8).
**Blockers**: None
**Process gate**: `gsd/instructions/` note + `STATUS.md` update before the PR; own branch
**Severity**: major 🟠, verified via post-merge render
**Plans**: TBD

### Phase 4: GitOps Application Identity
**Goal**: The Argo CD Application carries the project's real name, so the Application and its
AppProject agree and no `cloudcart` identity survives in the GitOps layer.
**Depends on**: Phase 1
**Requirements**: REQ-argocd-app-name
**Success Criteria** (what must be TRUE):
  1. `argocd-app.yaml` `Application.metadata` has exactly **one** `name:` key, and it is
     `sports-store` — the YAML last-wins duplicate is gone.
  2. Application and AppProject names agree; no `cloudcart` string remains in the file.
  3. The change is a single-concern diff on its own dedicated branch (C-4).
**Blockers**: None
**Process gate**: `gsd/instructions/` note + `STATUS.md` update before the PR; own branch
**Severity**: 🟠 major per `STATUS.md`, which outranks the risk scan and feedback note that
both grade it ℹ️ informational ("sync itself should still function"). Recorded as 🟠. This is
a severity difference, not a factual disagreement — the defect description is identical in
all four sources.
**Plans**: TBD

### Phase 5: MongoDB Persistence
**Goal**: MongoDB data outlives its pod — surviving restart, reschedule, `helm upgrade`,
rollback, and uninstall, as the brief requires.
**Depends on**: Phase 1 · **plus an external gate outside this repo's control (see Blockers)**
**Requirements**: REQ-mongodb-persistence
**Success Criteria** (what must be TRUE):
  1. Bitnami MongoDB persistence is enabled (`mongodb.persistence.enabled=true` plus
     `storageClass` and `size`), and a PVC / volumeClaimTemplate renders in place of
     `emptyDir: {}` at `/bitnami/mongodb`.
  2. Data survives install / upgrade / rollback / uninstall per constraint C-9 — the brief
     violation currently recorded in both `STATUS.md` and the risk scan is closed.
  3. The `mongo-init` seed no longer re-runs against a wiped datadir on every restart.
  4. `storageClass` is left unpinned in the chart until Sean confirms the actual EKS class —
     no value is guessed in.
**Blockers**: **EXTERNAL.** This phase requires a confirmed EKS StorageClass / EBS CSI driver
from **Sean** (`REQ-sean-infra`, `routable: no` in this repo — the ALB controller install,
the EBS StorageClass, and the required-extension implementation are all his). The
**chart-side** change is David's; the **storage availability** is not. Do not pin
`storageClass` before Sean confirms. This phase cannot be marked complete on render evidence
alone.
**Process gate**: `gsd/instructions/` note + `STATUS.md` update before the PR; own branch;
values change
**Severity**: critical 🔴, verified via post-merge render, **brief violation**
**Plans**: TBD

## Blocked / TBD — deliberately NOT phases

These are real, David-adjacent work items that are **not routed** because a decision is
missing. They are surfaced here so they are not forgotten, and are **not** to be collapsed
into a phase by any downstream planner.

### TBD-1: Frontend chart intent (REQ-frontend-chart-intent)

**Status**: 🚫 **BLOCKED ON A TEAM DECISION. No variant has been selected.**
**Owner**: David / team · **Severity**: 🟠 major per `STATUS.md`, ℹ️ per the feedback note

No Deployment and no Service render for the frontend. `environments/production/images.yaml`
defines a `frontend` image tag, but `frontend` is not in `.Values.services`, so the chart
deploys 6 backend/gateway workloads only. The public storefront is served outside this chart.

Two competing acceptance variants are preserved **verbatim** in
`.planning/REQUIREMENTS.md` and `.planning/INGEST-CONFLICTS.md` WARNING 2:

- **Variant A** — frontend is deliberately not chart-managed (roughly a documentation task).
- **Variant B** — frontend belongs in the chart (a chart change on its own branch, which
  interacts with C-7 and the existing ALB Ingress).

**Every source in the ingest defers; none picks.** `STATUS.md` says "Intent must be confirmed
with the team and the chart aligned to that decision." The two variants imply materially
different amounts of work and cannot be merged into one acceptance criterion. An unresolved
sub-question applies either way: **why does `images.yaml` carry a `frontend` tag that nothing
consumes?**

**Unblocking action**: confirm intent with the team (already listed in `STATUS.md` "Next up"),
then pick a variant. Only then does this become a phase.

### TBD-2: README accuracy (REQ-readme-accuracy)

**Status**: 🚫 **BLOCKED on INGEST-CONFLICTS WARNING 1. Derived, not source-asserted.**
**Owner**: David Rubin (docs are David-owned per D-4) · **Severity**: to be set by the user

No document in the ingest asked for this. It is inferred from the README staleness conflict
and is flagged as derived so it is not mistaken for stated intent. `README.md` is a **mixed
live/stale document**: its `k8s/` layout and raw-`kubectl-apply` order are superseded by the
Helm umbrella + Argo CD reality, but it is the **sole source** of three still-live
constraints — C-7 (gateway is the only externally reachable Service), C-8 (Service name ↔
`proxy_pass` coupling, which is what made the ingress duplicate-key defect a functional
routing break), and C-10 (apply ordering). Precedence alone would discard the file and lose
them.

**Unblocking action**: a **per-section** decision, not a per-document one. Recommended on
record: keep the Internal-service-DNS and ordering constraints, rewrite the Layout and
Suggested-apply-order sections, drop the "inline TODO comments" framing.

## Excluded from this roadmap (other owners — C-1)

Tracked, real, and **explicitly not phases here**. Flagged to the owner, never silently fixed.

| Item | Owner | Why excluded |
|---|---|---|
| REQ-eso-secrets-backend — ESO operator, AWS Secrets Manager `sports-store/production`, IRSA trust scoping | **Sean** | Highest-severity open item in the set (🔴 cross-team blocker) and not David's to fix. The chart cannot self-verify it. |
| AWS Load Balancer Controller install | **Sean** | Infrastructure |
| EBS StorageClass / EBS CSI availability | **Sean** | Infrastructure — this is the external gate on Phase 5 |
| REQ-metrics-endpoints — `/metrics` on service `http` ports, `fix/ci-instrumentator` | **Daniel Rusman** | Service/application behavior. Pairs with Phase 2; both are required before metrics work. |
| REQ-mongo-password-property — root password == user password via one `MONGO_ROOT_PASSWORD` property | **Sean** | Secret design decision |
| Required-extension implementation (`sports-store-infrastructure` #6) | **Sean / infra** | Declared, not verified; infrastructure |
| REQ-e2e-verification — frontend → gateway → each API → data layer | **cross-team** | Not verified, and not provable from this repo. Never inferred from public-URL reachability (D-6). |
| CI cloud-auth model (OIDC vs static keys) | **Sean** | Explicitly not David's (D-5) |

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5.
Phases 2, 3, and 4 are mutually independent once Phase 1 closes and may be reordered by
severity or convenience; each is its own branch and PR regardless. Phase 5 is last because it
cannot close without an external answer.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Baseline Sync | 0/TBD | Not started | - |
| 2. Scrape Target Alignment | 0/TBD | Not started | - |
| 3. Namespace Consistency | 0/TBD | Not started | - |
| 4. GitOps Application Identity | 0/TBD | Not started | - |
| 5. MongoDB Persistence | 0/TBD | Blocked (external — Sean's EBS StorageClass) | - |

**Coverage:** 5 of 5 routable David-owned requirements mapped to phases · 1 standing
invariant checked by every phase · 2 items deliberately unrouted pending a team decision ·
5 items excluded per C-1 · **0 orphans**.
