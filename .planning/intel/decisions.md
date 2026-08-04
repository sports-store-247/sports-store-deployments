# Decisions

Synthesized from the ingest set. **There are zero ADRs in this doc set and nothing is
LOCKED.** No document in the set carries a `Status: Accepted` field, an ADR sequence
number, or a Context/Decision/Consequences structure.

The entries below are **binding rules carried by SPEC-precedence process documents**, not
architecture decision records. They are authoritative for process, but any of them can be
superseded by a normal PR — none require the LOCKED-decision override protocol.

---

## D-1 — Process contract: the five-stage GSD loop

- **source:** `GSD.md` (SPEC, precedence 0)
- **status:** binding, not locked
- **scope:** all work in `sports-store-deployments`

Work moves through `gsd/research/` → `gsd/instructions/` → `gsd/executions/` →
`gsd/verifications/` → `gsd/repo-feedback/`. Not every task needs all five files;
research and verification "should almost always exist for a real change."

File naming: research/dated notes `YYYY-MM-DD-<slug>.md`; instruction/execution/
verification notes `<topic>-<slug>.md`.

## D-2 — Separation of process contract from live status

- **source:** `GSD.md` (SPEC, precedence 0); rationale in `gsd/research/2026-08-03-docs-bootstrap.md` (DOC)
- **status:** binding, not locked

`GSD.md` holds the operating model and **no live status**. `STATUS.md` holds the live
dashboard and **no process rules**. `gsd/**` holds dated work notes.

The docs-bootstrap research note contains a `## Decision` heading, which is the only
ADR-shaped signal in the entire set. It carries no status field and no ADR number, so it
is treated as **rationale/context**, not a locked decision. Its recorded finding: no
`GSD.md` existed in the working tree, git history, other branches, or stash, so this was
a bootstrap rather than a split of an existing file.

## D-3 — Reviews are read-and-report only

- **source:** `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, precedence 2)
- **status:** binding, not locked

Repo-level agent reviews produce documentation only. No commits, no pushes, no PRs. No
edits to application code, Terraform, or Helm unless a follow-up task explicitly
authorizes it. Remediation is a separate, owner-approved task.

## D-4 — Ownership model (authoritative)

- **source:** `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, precedence 2), §"Ownership model (authoritative)"
- **corroborated by:** `STATUS.md` (PRD, precedence 1), §"Ownership & scope"
- **status:** binding, not locked

| Person | Owns |
|---|---|
| David Rubin | Deployments, Helm, GitOps, documentation, deployment readiness |
| Sean | Infrastructure, AWS, Terraform, EKS, ALB, ECR, CI cloud-authentication decisions (incl. OIDC) |
| Maxim | Review, coordination, repo hygiene, validation feedback. Reports blockers; not the implementation owner |
| Daniel Rusman | Service/application behavior, API contracts, service env requirements |

Two sources agree on this model with no divergence. See `constraints.md` C-1 for the
enforceable scope fence derived from it.

## D-5 — CI cloud-auth (OIDC vs static keys) decision belongs to Sean

- **source:** `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, precedence 2)
- **status:** binding, not locked

Explicitly **not David's**. Service-repo agents (Daniel) and the reviewer (Maxim) *report*
what they observe; they do not own the auth-model decision.

## D-6 — Reachability is a status signal, never E2E proof

- **source:** `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, precedence 2), §5.3
- **corroborated by:** `STATUS.md` (PRD, precedence 1), §"Verification state"; boundary sections of both verification notes
- **status:** binding, not locked

`https://sportsstore.seansite.org/` loading is a **project status signal**. It must not be
upgraded to "Full E2E verified" without API-level proof. Four separate documents assert
this; it is the single most consistently repeated rule in the set.

## D-7 — Status is written before any remediation PR

- **source:** `GSD.md` (SPEC, precedence 0), principle 6; restated in coordinator plan §5.8
- **status:** binding, not locked

`STATUS.md` and the relevant `gsd/` note must already describe what changed and why
*before* the PR is opened.

## D-8 — Namespace `sports-store` is fixed

- **source:** `GSD.md` (SPEC, precedence 0), principle 3
- **corroborated by:** `README.md` (DOC), coordinator plan §3 (SPEC)
- **status:** binding, not locked

Do not rename. All later stages (Helm chart, EKS deploy, CI/CD, Argo CD, observability)
assume the name. `cloudcart` occurrences are defects to be corrected toward
`sports-store`, never the reverse.

## D-9 — sports-store-local drives no deployment decisions

- **source:** `gsd/instructions/2026-08-03-coordinator-agent-plan.md` (SPEC, precedence 2), §3
- **status:** binding, not locked

Reference repo only. Parity/drift findings are informational.
