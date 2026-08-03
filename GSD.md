# GSD — Operating Model

This document defines **how work is run** in the `sports-store-deployments` repo.
It is the process contract only. It holds **no live status** — the current state of
the project lives in [`STATUS.md`](./STATUS.md).

> GSD = "Get the Structured work Done". A lightweight, auditable loop:
> **research → instructions → execution → verification → repo-feedback**.

---

## Principles

1. **Docs before changes.** Every non-trivial change starts as a written note under
   `gsd/`, not directly in the manifests.
2. **One concern per change.** A branch and its PR do one thing. Small, reviewable diffs.
3. **Namespace is fixed.** Everything targets the `sports-store` namespace. Do not rename it.
4. **No secrets in git.** Secret *values* never land in tracked files. Only references
   (`existingSecret`, env var names, placeholders) are committed.
5. **PR-gated `main`.** All changes reach `main` via pull request with at least one
   approval (enforced by the repository ruleset).

---

## The loop

Each unit of work moves through five stages, each backed by a folder under `gsd/`.

| Stage | Folder | What lands here |
|-------|--------|-----------------|
| 1. Research | `gsd/research/` | Investigation notes, options, decisions. Dated files. |
| 2. Instructions | `gsd/instructions/` | The concrete plan / steps to apply for a piece of work. |
| 3. Execution | `gsd/executions/` | What was actually run and the resulting diff/summary. |
| 4. Verification | `gsd/verifications/` | Evidence the change works (kubectl/helm output, checks). |
| 5. Repo feedback | `gsd/repo-feedback/` | Retros, follow-ups, and issues found for later. |

Not every task needs all five files. Research and verification are the two that
should almost always exist for a real change.

### File naming

- Research / dated notes: `YYYY-MM-DD-<slug>.md`
- Instruction / execution / verification notes: `<topic>-<slug>.md`

---

## Branching

- `feature/<short-description>` — new functionality
- `bugfix/<short-description>` — non-urgent fixes
- `hotfix/<short-description>` — urgent production fixes
- `docs/<short-description>` — documentation-only changes

Open a PR into `main`; at least one approval is required before merge.

---

## Scope guards

These files are **out of scope** for a docs task and must not be touched by it:

- Helm charts under `helm/`
- Terraform (when introduced)
- Application / service code

A change that needs to touch those goes through its own non-docs branch and PR.

---

## Where things live

- Process (this file): `GSD.md`
- Live status: `STATUS.md`
- Work notes: `gsd/**`
- Deployment manifests: repo root + `helm/`, `configmaps/`, `secrets/`, `mongodb/`, service dirs
