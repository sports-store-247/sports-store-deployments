# Sports Store Deployments

## What This Is

`sports-store-deployments` is the Kubernetes / Helm / GitOps deployment layer for the Sports
Store (a.k.a. CloudCart) microservices e-commerce platform — a React frontend, an NGINX
gateway, five backend services, and MongoDB. It owns the `helm/sports-store` umbrella chart
(with the Bitnami MongoDB subchart), the Argo CD `AppProject` + `Application` in
`argocd-app.yaml`, the External Secrets Operator wiring, and the deployment documentation.
It does not own the application code, the AWS infrastructure, or the CI cloud-auth model.

Current stage per `STATUS.md`: **Stage 3+** — Helm umbrella chart + Argo CD GitOps + ESO
restructure landed on `main`. Target runtime is Amazon EKS; local `kind`/`kubectl` is used
for validation only.

## Core Value

The chart and the GitOps Application must render and sync a correct, complete, persistent
`sports-store` deployment — so that what is committed to `main` is what actually runs.

## Requirements

### Validated

<!-- Shipped and confirmed by the post-merge render. -->

- ✓ All 6 app images pinned to `0.1.0-<7char-hash>`, no `latest` (F1) — Stage 3+
- ✓ Ingress backend resolves to Service `gateway`:80 in `sports-store` (F3) — Stage 3+
- ✓ All 6 ServiceMonitors render from `.Values.services` (F4) — Stage 3+
- ✓ ESO restructure renders; the old empty `secret.yaml` is gone — Stage 3+

### Active

<!-- Current scope. David-owned, routable in this repo. See REQUIREMENTS.md for detail. -->

- [ ] **REQ-refresh-local-from-main** — working base provably in sync with `main`
- [ ] **REQ-servicemonitor-label-match** — ServiceMonitor selectors match Service labels
- [ ] **REQ-mongo-init-namespace** — `mongo-init` ConfigMap renders the target namespace
- [ ] **REQ-argocd-app-name** — Argo CD Application named `sports-store`, not `cloudcart`
- [ ] **REQ-mongodb-persistence** — MongoDB data survives install/upgrade/rollback/uninstall
      *(externally blocked on Sean's EBS StorageClass)*
- [ ] **REQ-secrets-reference-only** — standing invariant, checked by every phase

### Blocked / Undecided

- **REQ-frontend-chart-intent** — TBD. Two competing variants preserved verbatim in
  REQUIREMENTS.md; **neither has been selected**. Awaiting team confirmation. Not a phase.
- **REQ-readme-accuracy** — derived, not asserted by any source document. Gated on
  INGEST-CONFLICTS WARNING 1 (per-section decision on README staleness). Not a phase.

### Out of Scope

<!-- Real tracked work owned by other people. C-1 forbids this repo acting on it. -->

- **REQ-eso-secrets-backend** (ESO operator, AWS Secrets Manager `sports-store/production`,
  IRSA trust scoping) — Sean. Highest-severity open item in the set, and not David's to fix.
- **AWS Load Balancer Controller install** — Sean.
- **EBS StorageClass / EBS CSI availability** — Sean. This is what REQ-mongodb-persistence waits on.
- **REQ-metrics-endpoints** (`/metrics` on service `http` ports, `fix/ci-instrumentator`) — Daniel Rusman.
- **REQ-mongo-password-property** (root password == user password via a single
  `MONGO_ROOT_PASSWORD` property) — Sean.
- **Required-extension implementation** (`sports-store-infrastructure` #6) — Sean / infra.
- **Full E2E API validation** — cross-team.
- **CI cloud-auth model (OIDC vs static keys)** — Sean. Explicitly not David's.
- **Cross-repo "fixes"** — forbidden. Findings outside scope are flagged to the owner, never
  silently fixed.

## Ownership

| Person | Owns |
|---|---|
| **David Rubin** | deployments / Helm / GitOps / docs |
| **Sean** | infrastructure / AWS / EKS / ALB / ECR / storage / secrets runtime |
| **Daniel Rusman** | service and application behavior, API contracts, /metrics endpoints |
| **Maxim** | review, coordination, repo hygiene |

## Verification Levels (do not conflate)

Two distinct levels of "working" are tracked separately. This distinction is the single most
repeated rule in the source documents (4 independent sources) and it is binding on every
report, phase verification, and success criterion in this project.

| Level | Meaning | Current |
|---|---|---|
| Reachable frontend / domain | `https://sportsstore.seansite.org/` loads and serves the app UI | ✅ **status signal only** (Sean) |
| Full E2E verified | Frontend → gateway → each API → data layer proven end-to-end | ❌ **NOT VERIFIED** |

No API/demo-flow evidence has been collected. **E2E remains unverified.** A phase may never
claim E2E success on the basis of the public URL loading. No phase in the current roadmap
achieves E2E — E2E is cross-team and out of scope for this repo.

Every verification note must state its boundary explicitly (C-12): what was rendered, what
was applied, what was not verified.

## Context

- **Architecture:** parent chart `helm/sports-store` with vendored Bitnami
  `charts/mongodb-16.5.20.tgz`. GitOps via `argocd-app.yaml` (AppProject + Application,
  automated sync). Secrets via ESO from AWS Secrets Manager `sports-store/production`,
  IRSA `sports-store-external-secrets-role`, `us-east-1`.
- **Rendered inventory:** 32 resources, `helm template --namespace sports-store`, exit 0,
  1519 lines, lint clean. 6 backend/gateway workloads + MongoDB. The frontend renders no
  workload — it is not in `.Values.services`.
- **Branching:** default branch `main`, PR-gated, 1 approval required.
- **Failure-mode mapping** (useful for sequencing): metrics-not-scraped is
  REQ-servicemonitor-label-match (David) + REQ-metrics-endpoints (Daniel) jointly; demo
  failure is a compound of MongoDB persistence + ESO secrets + ServiceMonitor labels, so it
  cannot be closed from this repo alone.
- **Superseded evidence:** the earlier `helm-template-render` note is the historical record
  of why the current state is correct. Its `microservices`-vs-`services` finding is fixed;
  the selector/label mismatch is a *second, different* defect in the same template.
- **`README.md` is a mixed live/stale document.** It describes a Stage 3 starter `k8s/` tree
  with inline `TODO` placeholders and a raw `kubectl apply` order that no longer matches
  reality — but it is the **only** source for constraints C-7, C-8, and C-10 below. Where
  `README.md` and `STATUS.md` disagree, `STATUS.md` and the current `gsd/` docs win.
- **Identifier hazard:** the tokens `R1`–`R10` mean *repositories* in the coordinator plan
  and *findings* in `STATUS.md` and the verification notes; a third `F1`–`F6` scheme overlaps
  the finding scheme. Always key on `REQ-<slug>` identifiers. Never key on the bare
  letter-number.

## Constraints

- **Scope (HARD)**: This repo may only plan and execute **David-owned** work — deployments,
  Helm, GitOps, docs (C-1). Work outside scope is flagged for the owning party, not silently
  fixed. Cross-repo fixes are forbidden.
- **Scope**: A documentation task must not touch `helm/`, Terraform, or application/service
  code (C-2). A change needing those goes through its own non-docs branch and PR.
- **Security**: Secret **values** never land in tracked files (C-3). Only references —
  `existingSecret`, env var names, placeholders. Any leaked value is an immediate fix.
  Agents must never add, print, or commit secret values.
- **Naming (fixed)**: The namespace is `sports-store` and **must not be renamed** (D-8). All
  later stages assume it. `cloudcart` occurrences are defects to correct toward
  `sports-store`, never the reverse.
- **Protocol**: The `gateway` Service is the **only** externally reachable Service (C-7).
  Everything else stays ClusterIP. Exactly one Ingress renders (`sports-store-gateway`).
- **Protocol**: Each backend Service `metadata.name` must match the hostname in the
  corresponding `gateway/nginx.conf` `proxy_pass` line (C-8). Changing a backend hostname
  requires updating the matching `proxy_pass` line **and rebuilding the gateway image**.
- **Protocol**: Ordering is secrets → MongoDB → app Deployments (C-10). MongoDB must be
  healthy before app Deployments connect, and that ordering must come from retry-friendly app
  startup or an `initContainer` — **not from a `readinessProbe` alone** — and the chosen
  approach must be documented. (The dependency ordering is live; the raw `kubectl apply`
  commands README describes are not.)
- **NFR**: MongoDB persistent data should survive install/upgrade/rollback/uninstall (C-9).
  The current `emptyDir` render is a **brief violation**.
- **Process**: All changes reach `main` via PR with at least 1 approval, enforced by
  repository ruleset (C-4). A branch and its PR do **one thing**.
- **Process**: Every non-trivial change starts as a written note under `gsd/`, not directly
  in the manifests (C-5).
- **Process**: `STATUS.md` and the relevant `gsd/` note describe what changed and why
  **before** the remediation PR is opened (D-7).
- **Process**: Anything affecting shared team process, cross-repo ownership, or another
  owner's area is raised with that owner first — never a surprise PR (C-6).
- **Process**: Work moves through `gsd/research/` → `gsd/instructions/` → `gsd/executions/`
  → `gsd/verifications/` → `gsd/repo-feedback/` (D-1). Research and verification "should
  almost always exist for a real change."
- **Naming**: Repo review reports land at
  `gsd/repo-feedback/2026-08-03-<repo-slug>-review.md` and carry repo name, date, checks run,
  findings (severity + owner), evidence, and explicit "not verified" notes (C-11).
- **Reference only**: `sports-store-local` drives no deployment decisions (D-9). Parity/drift
  findings are informational.

## Key Decisions

**There are zero ADRs in this project and nothing is LOCKED.** The rows below are binding
process rules carried by SPEC-precedence documents (`GSD.md`, the coordinator agent plan).
They are authoritative for process but **revisable by an ordinary PR** — none require a
locked-decision override protocol.

| Decision | Rationale | Outcome |
|---|---|---|
| D-1 Five-stage GSD loop (`research`→`instructions`→`executions`→`verifications`→`repo-feedback`) | Each stage leaves a dated artifact, so the loop is auditable | — Pending |
| D-2 `GSD.md` holds process and no live status; `STATUS.md` holds live status and no process rules | Status churns constantly; a process doc that never carries live data stays trustworthy | ✓ Good |
| D-3 Repo-level agent reviews are read-and-report only — no commits, pushes, or PRs | Remediation is a separate, owner-approved task | — Pending |
| D-4 Ownership model (David / Sean / Maxim / Daniel) is authoritative | Two independent sources agree with no divergence | ✓ Good |
| D-5 CI cloud-auth (OIDC vs static keys) decision belongs to Sean | Not David's; others report what they observe, they do not decide | ✓ Good |
| D-6 Reachability is a status signal, never E2E proof | Asserted by 4 separate documents; conflating them would falsely close the demo risk | ✓ Good |
| D-7 `STATUS.md` is written before any remediation PR | The reviewer sees intent before diff | — Pending |
| D-8 Namespace `sports-store` is fixed | Chart, EKS deploy, CI/CD, Argo CD, and observability all assume the name | ✓ Good |
| D-9 `sports-store-local` drives no deployment decisions | Reference repo only | ✓ Good |

---
*Last updated: 2026-08-04 after document ingest (11 source docs, 0 ADRs, 0 locked decisions)*
