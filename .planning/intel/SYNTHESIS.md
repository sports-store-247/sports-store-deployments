# Synthesis

Entry point for downstream consumers (gsd-roadmapper). Produced by gsd-doc-synthesizer
from 11 per-doc classifications in `.planning/intel/classifications/`.

Mode: **new** — no pre-existing `.planning/` context.
Repo: `sports-store-deployments` — the Kubernetes/Helm/GitOps deployment layer for the
Sports Store microservices platform.

---

## Doc counts by type

| Type | Count | Sources |
|---|---|---|
| ADR | **0** | — |
| SPEC | 2 | `GSD.md` (prec 0), `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (prec 2) |
| PRD | 1 | `STATUS.md` (prec 1) |
| DOC | 8 | `README.md`, 2 verifications, 2 repo-feedback, 3 research |
| **Total** | **11** | all consumed, all confidence `high`, all `manifest_override: true` |

This repo uses a homegrown `gsd/` note tree, not ADR/PRD/SPEC conventions. Every type
assignment came from the manifest, not from content heuristics. Six documents carry a
`2026-08-03-` filename prefix that superficially resembles ADR numbering; none is an ADR.

## Decisions

**Locked: 0.** No ADRs exist and nothing in the set is marked `locked: true`. The
LOCKED-decision protection machinery never engaged.

9 binding-but-unlocked process rules extracted to `decisions.md`, carried by the two SPEC
documents:

- D-1 five-stage GSD loop · D-2 process/status separation · D-3 reviews are read-and-report
  only · D-4 ownership model · D-5 CI cloud-auth decision is Sean's · D-6 reachability is
  never E2E proof · D-7 status before remediation PR · D-8 namespace `sports-store` is fixed
  · D-9 sports-store-local drives no decisions

D-6 is the most consistently repeated rule in the set (4 independent sources).

## Requirements

**8 routable-or-tracked + 5 explicitly not-routable = 13 total.** See `requirements.md`.

Routable in this repo (David-owned):
- `REQ-servicemonitor-label-match` (R1) — critical, verified, unblocked
- `REQ-mongo-init-namespace` (R4) — major, verified, unblocked
- `REQ-argocd-app-name` (F2) — major, verified, unblocked
- `REQ-refresh-local-from-main` (F5) — housekeeping, may already be satisfied
- `REQ-mongodb-persistence` (R2) — critical, **externally blocked** on Sean's EBS StorageClass
- `REQ-frontend-chart-intent` (F6) — **blocked on a decision**, competing variants preserved
- `REQ-secrets-reference-only` — standing invariant, not a phase
- `REQ-readme-accuracy` — **derived, not source-asserted**, gated on WARNING 1

Not routable here (`routable: no`, see `constraints.md` C-1):
- `REQ-eso-secrets-backend` (R3, Sean) — highest-severity open item in the set
- `REQ-metrics-endpoints` (R5, Daniel)
- `REQ-sean-infra` (ALB controller, EBS StorageClass, required extension — Sean)
- `REQ-mongo-password-property` (R6, Sean)
- `REQ-e2e-verification` (cross-team)

## Constraints

**12 extracted** to `constraints.md`:

| Type | Items |
|---|---|
| scope | C-1 ownership fence (HARD), C-2 docs-task scope guards |
| process | C-4 PR-gated main, C-5 docs before changes, C-6 coordinate before PR, C-12 verification boundary |
| protocol | C-7 gateway-only external, C-8 gateway DNS/proxy_pass coupling, C-10 apply ordering |
| nfr | C-3 no secret values in git, C-9 MongoDB persistence is a brief requirement |
| naming | C-11 repo review report path contract |

**C-1 is the constraint that most shapes routing** — it determines which STATUS.md items
may legitimately become phases in this repo.

## Context

**10 topics** in `context.md`: current architecture · post-merge verification evidence ·
risk-to-failure-mode mapping · superseded earlier render · org delta cross-repo sweep ·
open questions for the team · recommended next safe action · documentation structure
rationale · coordinator review plan status · legacy Stage 3 layout.

## Conflicts

**0 blockers · 2 competing-variants/warnings · 12 auto-resolved/info.**

Full detail: `.planning/INGEST-CONFLICTS.md`

Warnings requiring user resolution before routing:
1. **README.md documents a superseded structure** — mixed live/stale document. Precedence
   would discard it, but it is the sole source of three still-live constraints (C-7, C-8,
   C-10). Needs a per-section decision, not a per-document one.
2. **Competing acceptance variants for `REQ-frontend-chart-intent`** — Variant A (document
   the exclusion, close) vs Variant B (add frontend to the chart). Both preserved verbatim;
   neither selected. Every source defers.

Notable auto-resolutions (all by precedence, never by date or filename order):
- STATUS.md (prec 1) overrides the coordinator plan (prec 2) twice — on the app-secrets
  empty `stringData` item and on the OIDC regression. The manifest's per-doc override
  inverts the default ADR>SPEC>PRD ordering here.
- STATUS.md adjudicates a direct DOC-vs-DOC contradiction on ServiceMonitor rendering that
  same-tier precedence could not break and a timestamp tiebreak was not permitted to break.

One judgment call is flagged for override: the `GSD.md <-> STATUS.md` reference cycle was
classified navigational rather than definitional, so synthesis proceeded on both. Treating
it as a hard cycle would have excluded the two highest-precedence documents and gutted the
ingest. See INFO 7.

---

## Routing guidance

- **Do not generate phases** for anything marked `routable: no` in `requirements.md`.
  Those are real tracked work items owned by Sean, Daniel, or the team at large, and
  `constraints.md` C-1 forbids this repo acting on them.
- **Resolve both WARNINGs** before routing `REQ-frontend-chart-intent` or
  `REQ-readme-accuracy`.
- **Sequencing hint:** the risk-to-failure-mode table in `context.md` shows R1 (David) and
  R5 (Daniel) are jointly required before metrics work, and that demo failure is a compound
  of R2 + R3 + R1. R1, R4, and F2 are the three fully unblocked David-owned items.
- **Every phase must honour** C-2 (docs tasks touch no Helm/Terraform/app code), C-3 (no
  secret values), C-4 (one concern per PR, 1 approval), and C-5/D-7 (write the
  `gsd/instructions/` note and update STATUS.md before the remediation PR).

## Files

- `.planning/intel/decisions.md`
- `.planning/intel/requirements.md`
- `.planning/intel/constraints.md`
- `.planning/intel/context.md`
- `.planning/INGEST-CONFLICTS.md`
