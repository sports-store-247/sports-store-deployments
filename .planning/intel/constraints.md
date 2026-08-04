# Constraints

Extracted from SPEC-precedence documents (`GSD.md` prec 0, coordinator plan prec 2) plus
the still-live constraint block in `README.md` (DOC).

Constraint type legend: `process` | `scope` | `protocol` | `nfr` | `naming`

---

## C-1 — Ownership scope fence (HARD)

- **source:** `STATUS.md` (PRD, prec 1) §"Ownership & scope"; `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, prec 2) §"Ownership model (authoritative)" and §7
- **type:** scope

This repo may only plan and execute **David-owned** work. The following are tracked in
`STATUS.md` but are **explicitly not David-owned and must not become phases in this
repo's roadmap**:

- **R3** — ESO operator provisioning, AWS Secrets Manager `sports-store/production`
  population, IRSA trust scoping → **Sean**
- **ALB controller install** → **Sean**
- **EBS StorageClass / EBS CSI availability** (which R2 depends on) → **Sean**
- **R5** — `/metrics` endpoints on the service `http` ports, `fix/ci-instrumentator` →
  **Daniel**
- **R6** — Mongo root/user password property design → **Sean**
- **Required-extension implementation** → **Sean / infra**
- **Full E2E API validation** → **cross-team**

Work outside the current scope is "flagged for the owning party, not silently fixed"
(`GSD.md` §Team coordination). Cross-repo "fixes" are forbidden (coordinator plan §3).

## C-2 — Docs-task scope guards

- **source:** `GSD.md` (SPEC, prec 0) §"Scope guards"
- **type:** scope

A documentation task must **not** touch:
- Helm charts under `helm/`
- Terraform (when introduced)
- Application / service code

A change needing those goes through its own non-docs branch and PR.

## C-3 — No secret values in git

- **source:** `GSD.md` (SPEC, prec 0) principle 4; `STATUS.md` (PRD, prec 1) item SECRETS; coordinator plan §3 (SPEC, prec 2)
- **type:** nfr / security

Secret *values* never land in tracked files. Only references (`existingSecret`, env var
names, placeholders) are committed. Any leaked value is an immediate fix. Agents must
never add, print, or commit secret values — reference names only.

## C-4 — PR-gated `main`, one concern per change

- **source:** `GSD.md` (SPEC, prec 0) principles 2 and 5; `README.md` (DOC) §"Branching convention"
- **type:** process

All changes reach `main` via pull request with **at least one approval** (enforced by
repository ruleset). A branch and its PR do one thing; small, reviewable diffs.

Branch prefixes: `feature/`, `bugfix/`, `hotfix/`, `docs/` (the `docs/` prefix appears in
`GSD.md` only; `README.md` lists the first three).

## C-5 — Docs before changes

- **source:** `GSD.md` (SPEC, prec 0) principle 1
- **type:** process

Every non-trivial change starts as a written note under `gsd/`, not directly in the
manifests. Reinforced by the post-merge feedback action queue: "Record the R1/R2 fix plans
as `gsd/instructions/` notes before editing Helm."

## C-6 — Coordinate before PR

- **source:** `GSD.md` (SPEC, prec 0) principle 7 and §"Team coordination"
- **type:** process

Anything affecting shared team process, cross-repo ownership, or another owner's area is
raised with that owner first — never opened as a surprise PR. No autonomous
process-affecting PRs.

## C-7 — Gateway is the only externally reachable Service

- **source:** `README.md` (DOC) §"Internal service DNS"; corroborated by `gsd/verifications/2026-08-03-helm-template-render.md` finding 5 and coordinator plan §2/R1
- **type:** protocol

Only the `gateway` Service may be externally exposed (NodePort/LoadBalancer/Ingress). All
other Services stay ClusterIP. Verified holding: exactly one `Ingress` renders
(`sports-store-gateway`).

**Live despite README staleness** — see `INGEST-CONFLICTS.md` WARNING 1.

## C-8 — Gateway DNS / proxy_pass coupling

- **source:** `README.md` (DOC) §"Internal service DNS"
- **type:** protocol

Each backend Service `metadata.name` must match the hostname used in the corresponding
`gateway/nginx.conf` `proxy_pass` line, or the gateway fails DNS resolution. Changing a
backend hostname requires updating the matching `proxy_pass` line **and rebuilding the
gateway image**.

**Live despite README staleness** — this is the constraint that made the F3/ingress
`service.name` duplicate-key defect a functional routing break rather than a cosmetic one.

## C-9 — MongoDB persistence is a brief requirement

- **source:** `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` (DOC) R2; `STATUS.md` (PRD, prec 1) R2
- **type:** nfr

"MongoDB persistent data should survive install/upgrade/rollback/uninstall." Current
`emptyDir` render is recorded in both sources as a **brief violation**.

## C-10 — Ordering: secrets before MongoDB before app Deployments

- **source:** `README.md` (DOC) §"Suggested apply order"
- **type:** protocol

Secrets must exist before MongoDB values and app Deployments, since all reference
`app-secrets`. MongoDB must be healthy before app Deployments connect; ordering must come
from retry-friendly app startup or an `initContainer`, **not `readinessProbe` alone**, and
the chosen approach must be documented.

**Partially stale** — the apply mechanism described in `README.md` (raw `kubectl apply`
per directory + standalone `helm install mongodb`) no longer matches the Helm-umbrella +
Argo CD reality. The *dependency ordering* remains live; the *commands* do not. See
`INGEST-CONFLICTS.md` WARNING 1.

## C-11 — Report path contract for repo reviews

- **source:** `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, prec 2) §4
- **type:** naming

Repo review reports land at `gsd/repo-feedback/2026-08-03-<repo-slug>-review.md` and must
contain: repo name, date, checks run, findings (severity + owner), evidence
(command output / `file:line`), and explicit "not verified" notes. The copy under this
repo's `gsd/repo-feedback/` is the coordinator's source of truth.

## C-12 — Verification boundary must be stated

- **source:** boundary sections of `gsd/verifications/2026-08-03-helm-template-render.md` and `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` (DOC)
- **type:** process

Both verification notes end with an explicit boundary: template render only, nothing
applied to a cluster, E2E not verified. This pattern is the repo's de-facto standard for
evidence notes and pairs with D-6.
