# Research — Docs bootstrap (split GSD vs. STATUS)

_Date: 2026-08-03 · Branch: `docs/helm-secret-bootstrap`_

## Problem

Documentation intent was for a single `GSD.md` to hold three different things at once:
the GSD operating model, live dashboard content, and some pasted freeform (Hebrew)
instructions. Mixing a stable **process contract** with **live status** makes both
harder to maintain — status churns constantly while the process should be stable.

## Finding

On inspection, no `GSD.md` existed yet in the working tree, git history, other
branches, or stash. So this is a **bootstrap**, not a literal split of an existing
file — the clean target structure was created from scratch.

## Decision

Separate concerns into two files plus a work-folder scaffold:

- `GSD.md` — operating model only (principles, the five-stage loop, branching, scope guards).
- `STATUS.md` — live dashboard only (snapshot, components, activity, next up).
- `gsd/` — five stage folders: `research/`, `instructions/`, `executions/`,
  `verifications/`, `repo-feedback/`.

## Rationale

- A process doc that never carries live data stays trustworthy over time.
- A dashboard that owns all volatile state gives one obvious place to check "where are we".
- The `gsd/` folders make the loop auditable: each stage leaves a dated artifact.

## Constraints honored

- Docs-only change. No Helm, Terraform, or application code touched.
- No secret values introduced.
- No commit / push / PR from this task.

## Follow-ups

- Add the first `gsd/verifications/` note once the MongoDB seed is validated live.
- Keep `STATUS.md` current as branches merge into `main`.
