# Requirements: Sports Store Deployments

**Defined:** 2026-08-04 (from document ingest — 11 source docs, 0 ADRs, 0 locked decisions)
**Core Value:** The chart and the GitOps Application must render and sync a correct,
complete, persistent `sports-store` deployment — so that what is committed to `main` is
what actually runs.

> **Identifier warning.** The tokens `R1`–`R10` mean **repositories** in the coordinator
> agent plan and **findings** in `STATUS.md` and the verification notes. A third `F1`–`F6`
> scheme overlaps the finding scheme (`F2` is also `R7`; `F6` is also `R8` in the feedback
> note). Everything here is keyed on **`REQ-<slug>`**. Source letter-numbers appear only as
> parenthetical cross-references. **Never key on the bare letter-number.**

> **Precedence.** `STATUS.md` (PRD, prec 1) and the current `gsd/` docs outrank `README.md`,
> which is stale on repo structure and apply order.

---

## v1 Requirements

David-owned work that is routable in this repo. Each maps to exactly one roadmap phase,
except the standing invariant, which is checked by every phase.

### Baseline

- [ ] **REQ-refresh-local-from-main** *(source: org-delta summary, item F5 · severity:
      immediate)*
      Merge/rebase `docs/helm-secret-bootstrap` onto post-restructure `main` (#17/#18) before
      further deployment work; commit pending `STATUS.md` / `GSD.md` / coordinator docs on the
      current base first.
      **Caveat (carried):** `STATUS.md` reports the active branch `gsd/post-merge-full-risk-scan`
      as **in sync with `main`**, which suggests this may already be satisfied. `STATUS.md`
      outranks the org-delta summary — **verify before treating this as live work.**

### Observability wiring

- [ ] **REQ-servicemonitor-label-match** *(source: `STATUS.md` item R1 · severity: critical 🔴 ·
      verified: yes · owner: David Rubin · routable: yes)*
      ServiceMonitor `spec.selector.matchLabels` expects `app.kubernetes.io/name: <service>`,
      but rendered Services carry `app.kubernetes.io/name: sports-store` from the shared
      `sports-store.labels` helper. No Service matches any of the 6 ServiceMonitors →
      Prometheus scrapes nothing.
      **Acceptance** (single variant, both sources agree):
      - Selector and Service labels agree — either add `app.kubernetes.io/name: <service>` to
        the Service labels, **or** change the selector to `app: <service>` which the Services
        already carry.
      - Proven with `helm template` that the selector labels exist on the target Service.
      - Planned as a `gsd/instructions/` note first, on its own branch.
      **Note:** necessary but **not sufficient** for metrics — `REQ-metrics-endpoints`
      (Daniel-owned, not routable here) must also land.

### Manifest correctness

- [ ] **REQ-mongo-init-namespace** *(source: `STATUS.md` item R4 · severity: major 🟠 ·
      verified: yes · owner: David Rubin · routable: yes)*
      `templates/mongo-init-configmap.yaml` omits `namespace: {{ .Values.namespace.name }}`,
      unlike every other template. Correct under Argo CD (destination ns + CreateNamespace),
      but lands in `default` under a raw `kubectl apply -f` without `-n`.
      **Acceptance:**
      - `namespace: {{ .Values.namespace.name }}` added to the `mongo-init` ConfigMap.
      - Namespace consistency holds across all rendered resources with no exception.

- [ ] **REQ-argocd-app-name** *(source: `STATUS.md` item F2 · severity: major 🟠 ·
      verified: yes · owner: David Rubin · routable: yes)*
      `argocd-app.yaml` `Application.metadata` has a duplicate `name:` key
      (`name: sports-store` then `name: cloudcart`). YAML last-wins → the Application is named
      `cloudcart`. The `AppProject` is correctly named `sports-store`.
      **Acceptance:**
      - Duplicate `name:` key removed; Application named `sports-store`.
      - One-line correction on a dedicated branch.
      **Severity note:** the risk scan and feedback note both grade this ℹ️ informational /
      cosmetic ("sync itself should still function"), while `STATUS.md` grades it 🟠 major.
      `STATUS.md` holds higher precedence, so 🟠 is recorded. This is a severity difference,
      not a factual contradiction.

### Data durability

- [ ] **REQ-mongodb-persistence** *(source: `STATUS.md` item R2 · severity: critical 🔴 ·
      verified: yes · **brief violation** · owner: David Rubin · routable: **yes, but
      externally blocked**)*
      MongoDB renders as a Deployment (not StatefulSet); the `datadir` volume at
      `/bitnami/mongodb` is `emptyDir: {}`. No PVC or volumeClaimTemplate renders. Data does
      not survive pod restart/reschedule/`helm upgrade`/rollback/uninstall, and the
      `mongo-init` seed re-runs on every restart.
      **Acceptance:**
      - Bitnami MongoDB persistence enabled (`mongodb.persistence.enabled=true` plus
        `storageClass`/`size`).
      - Data survives install/upgrade/rollback/uninstall per the brief (constraint C-9).
      - Own branch; values change.
      **Blocker (external):** requires a confirmed EKS StorageClass / EBS CSI driver from
      **Sean**. The `storageClass` value **must not be pinned before Sean confirms**. The
      *chart-side* work is David's; the *storage availability* is not.

### Standing invariant

- [ ] **REQ-secrets-reference-only** *(source: `STATUS.md` item SECRETS · severity: standing ·
      verified: yes · owner: David Rubin · routable: **standing constraint, not a phase**)*
      Secrets stay reference-only in git; any leaked value is an immediate fix. Functionally a
      permanent guardrail (constraint C-3) — **treated as an invariant checked by every phase,
      not a phase of its own.**

---

## Blocked / undecided — deliberately NOT routed as phases

### REQ-frontend-chart-intent

- **source:** `STATUS.md` (PRD, prec 1) item F6 · also `R8` in the post-merge feedback note
- **owner:** David / team — **routable: BLOCKED ON DECISION**
- **severity:** major 🟠 per `STATUS.md`; ℹ️ per the feedback note

No Deployment and no Service render for the frontend. `environments/production/images.yaml`
defines a `frontend` image tag, but `frontend` is not in `.Values.services`, so the chart
deploys 6 backend/gateway workloads only. The public storefront is served outside this chart.

**⚠ COMPETING ACCEPTANCE VARIANTS — not merged, not selected. The team must choose.**
See `INGEST-CONFLICTS.md` WARNING 2.

Recorded verbatim from `intel/requirements.md`:

> - **Variant A — frontend is deliberately not chart-managed.** Acceptance: the intent is
>   documented, the stray `frontend` entry in `images.yaml` is reconciled or explained, and
>   the item closes with no workload added.
> - **Variant B — frontend should be chart-managed.** Acceptance: `frontend` added to
>   `.Values.services`; Deployment and Service render; routing/ingress implications resolved.

Recorded verbatim from `INGEST-CONFLICTS.md` WARNING 2 (fuller phrasing):

> Variant A - frontend is deliberately out of chart. Acceptance: document the intent,
> reconcile the orphaned frontend entry in images.yaml, close with no workload added.
> Roughly a documentation task.
> Variant B - frontend belongs in the chart. Acceptance: add frontend to
> .Values.services, render a Deployment and Service, resolve routing/ingress
> implications. A chart change on its own branch, and it interacts with C-7 (gateway
> as sole external entrypoint) and with the existing ALB Ingress.

**No document in the set picks a variant.** `STATUS.md` says "Intent must be confirmed with
the team and the chart aligned to that decision" — it defers rather than deciding. The two
variants imply materially different amounts of work and cannot be collapsed. There is also an
unresolved sub-question either way: **why does `images.yaml` carry a `frontend` tag that
nothing consumes?**

**Routing disposition:** no phase is emitted. This is surfaced in ROADMAP.md as a blocked/TBD
item awaiting team confirmation. Do not let a downstream planner collapse the variants.

### REQ-readme-accuracy *(derived — not asserted by any source doc)*

- **derived from:** conflict between `README.md` (DOC) and `STATUS.md` (PRD, prec 1)
- **owner:** David Rubin (docs are David-owned per D-4) — **routable: after WARNING 1 resolved**
- **severity:** to be set by user

**This requirement was not stated by any document.** It is inferred from the README staleness
conflict and is flagged as derived so it is not mistaken for source-asserted intent.
`README.md` documents a Stage 3 starter state (inline `TODO` placeholders, `k8s/` per-service
directories, standalone `helm install mongodb`) that predates the Helm-umbrella + Argo CD +
ESO structure recorded in `STATUS.md`.

`README.md` is a **mixed live/stale document** and cannot be resolved by precedence, because
it is the sole source of three still-live constraints: C-7 (gateway is the only externally
reachable Service), C-8 (Service name ↔ `proxy_pass` coupling), and C-10 (apply ordering).
Discarding it would lose them; keeping it whole propagates a false picture of the repo.

**Routing disposition:** no phase is emitted. Requires a **per-section** decision, not a
per-document one, before it becomes real work. Recommended resolution on record: keep the
Internal-service-DNS and ordering constraints, rewrite the Layout and Suggested-apply-order
sections to match the Helm umbrella + Argo CD reality, and drop the "inline TODO comments"
framing.

---

## Not routable in this repo (track only)

Real, tracked work items — but constraint C-1 forbids them becoming phases here. Listed so
they are visible and **deliberately excluded** from ROADMAP.md.

| Requirement | Owner | Routable | Severity | Summary |
|---|---|---|---|---|
| **REQ-eso-secrets-backend** (`STATUS.md` R3) | **Sean** | **no** | critical 🔴, cross-team blocker | `app-secrets` and Mongo URIs come from AWS Secrets Manager `sports-store/production` via ESO, using IRSA `sports-store-external-secrets-role` in `us-east-1`. `ExternalSecret/app-secrets-eso` carries `JWT_SECRET` plus the five `*_MONGO_URI` properties, `refreshInterval: 1h`. Missing ESO operator, secret, properties, or IRSA → `app-secrets` never created → pods not ready → ALB 503 → demo fails. All `*_MONGO_URI` values must resolve `sports-store-mongodb:27017`. The chart cannot self-verify this. **Highest-severity open item in the set, and not David's to fix.** |
| **REQ-metrics-endpoints** (`STATUS.md` R5) | **Daniel Rusman** | **no** | tracked/major | `/metrics` must be exposed on the services' `http` ports. ServiceMonitor endpoint is `port: http`, `path: /metrics`; gateway listens on 8080 (Service 80→8080). Tracked via `fix/ci-instrumentator` PRs. **Pairs with REQ-servicemonitor-label-match** — both are required before metrics work. |
| **REQ-sean-infra** (`STATUS.md` SEAN-INFRA) | **Sean** | **no** | tracked | AWS Load Balancer Controller install; **EBS StorageClass needed for REQ-mongodb-persistence**; implementation of the declared required extension (`sports-store-infrastructure` #6, declared but not verified). |
| **REQ-mongo-password-property** (risk scan / feedback R6) | **Sean** | **no** | informational | `mongodb-credentials-eso` maps both `mongodb-root-password` and `mongodb-passwords` from the single `MONGO_ROOT_PASSWORD` property — functional, but root password equals user password. Secret design decision. **Gap note:** present in two DOC sources, absent from `STATUS.md`'s open lists; preserved for completeness (INFO 9). |
| **REQ-e2e-verification** (`STATUS.md` E2E) | **cross-team** | **no** | constraint · **not verified** | Frontend → gateway → each API → data layer is unproven. No API/demo-flow evidence collected. Frontend/domain reachability is only a status signal and **must never be conflated with E2E in any report** (D-6). |

---

## Resolved before this roadmap (no longer open)

Recorded so they are not re-opened by a stale document.

| Item | Evidence |
|---|---|
| F1 — image tags | All 6 app images `0.1.0-<7char-hash>`: auth `686e7cd`, cart `6e0f5cc`, catalog `06243ee`, gateway `11ea172`, order `1661894`, payment `2738bd5`; MongoDB `mongo:8.0`. No `latest`. |
| F3 — ingress routing | Ingress backend `service.name: gateway`, `port.number: 80` matches rendered `Service/gateway` (ClusterIP, port 80). |
| F4 — ServiceMonitor rendering | 6 ServiceMonitors now render. The `.Values.microservices` vs `.Values.services` bug is fixed; **REQ-servicemonitor-label-match is a separate, still-open defect in the same template.** |
| app-secrets empty `stringData` | Superseded by the #17/#18 ESO restructure. |
| OIDC regression | Resolved — all 7 service repos merged the OIDC revert. Sean/CI decision. |

---

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| REQ-refresh-local-from-main | Phase 1 | Pending |
| REQ-servicemonitor-label-match | Phase 2 | Pending |
| REQ-mongo-init-namespace | Phase 3 | Pending |
| REQ-argocd-app-name | Phase 4 | Pending |
| REQ-mongodb-persistence | Phase 5 | Blocked (external — Sean's EBS StorageClass) |
| REQ-secrets-reference-only | *all phases (invariant)* | Standing |
| REQ-frontend-chart-intent | *none — TBD* | Blocked (team decision: Variant A vs B) |
| REQ-readme-accuracy | *none — TBD* | Blocked (WARNING 1, per-section decision) |
| REQ-eso-secrets-backend | *none — Sean* | Not routable here |
| REQ-metrics-endpoints | *none — Daniel Rusman* | Not routable here |
| REQ-sean-infra | *none — Sean* | Not routable here |
| REQ-mongo-password-property | *none — Sean* | Not routable here |
| REQ-e2e-verification | *none — cross-team* | Not routable here |

**Coverage:**
- Requirements recorded: **13** (8 David-owned or tracked here + 5 explicitly not routable)
- Mapped to phases: **5** — every requirement that is both David-owned and unblocked-by-decision
- Standing invariant (checked by every phase, never a phase): **1**
- Deliberately unrouted, blocked on a team decision: **2** (frontend chart intent, README accuracy)
- Deliberately excluded per C-1 (other owners): **5**
- **Orphans: 0** ✓ — every requirement has an explicit disposition

---
*Requirements defined: 2026-08-04*
*Last updated: 2026-08-04 after document ingest*
