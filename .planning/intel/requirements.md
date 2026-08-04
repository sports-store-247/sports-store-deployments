# Requirements

Primary source: `STATUS.md` (PRD, precedence 1) — the manifest designates its open work
items as the primary requirement material. Corroborating detail is pulled from the DOC
verification and feedback notes, which agree with `STATUS.md` on every open item.

Each requirement is tagged `owner:` and `routable:`. **`routable: no` means the item must
not become a phase in this repo** — see `constraints.md` C-1.

---

## REQ-servicemonitor-label-match

- **source:** `STATUS.md` (PRD, prec 1) item R1
- **evidence:** `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` R1; `gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md` R1
- **owner:** David Rubin — **routable: yes**
- **severity:** critical (🔴) · **verified:** yes

ServiceMonitor `spec.selector.matchLabels` expects `app.kubernetes.io/name: <service>`,
but rendered Services carry `app.kubernetes.io/name: sports-store` from the shared
`sports-store.labels` helper. No Service matches any of the 6 ServiceMonitors → Prometheus
scrapes nothing.

**Acceptance criteria** (single variant, both sources agree):
- Selector and Service labels agree — either add `app.kubernetes.io/name: <service>` to
  the Service labels, **or** change the selector to `app: <service>` which the Services
  already carry.
- Proven with `helm template` that the selector labels exist on the target Service.
- Planned as a `gsd/instructions/` note first, on its own branch.

**Note:** fixing this is necessary but not sufficient for metrics — REQ-metrics-endpoints
(Daniel-owned) must also land.

## REQ-mongodb-persistence

- **source:** `STATUS.md` (PRD, prec 1) item R2
- **evidence:** `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` R2; `gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md` R2
- **owner:** David Rubin — **routable: yes, but externally blocked**
- **severity:** critical (🔴) · **verified:** yes · **brief violation**

MongoDB renders as a Deployment (not StatefulSet); the `datadir` volume at
`/bitnami/mongodb` is `emptyDir: {}`. No PVC or volumeClaimTemplate renders. Data does not
survive pod restart/reschedule/`helm upgrade`/rollback/uninstall, and the `mongo-init`
seed re-runs on every restart.

**Acceptance criteria:**
- Bitnami MongoDB persistence enabled (`mongodb.persistence.enabled=true` plus
  `storageClass`/`size`).
- Data survives install/upgrade/rollback/uninstall per the brief (see `constraints.md` C-9).
- Own branch; values change.

**Blocker:** requires a confirmed EKS StorageClass / EBS CSI driver from Sean. The
`storageClass` value must not be pinned before Sean confirms. The *chart-side* work is
David's; the *storage availability* is not.

## REQ-mongo-init-namespace

- **source:** `STATUS.md` (PRD, prec 1) item R4
- **evidence:** `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` R4; `gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md` R4
- **owner:** David Rubin — **routable: yes**
- **severity:** major (🟠) · **verified:** yes

`templates/mongo-init-configmap.yaml` omits `namespace: {{ .Values.namespace.name }}`,
unlike every other template. Correct under Argo CD (destination ns + CreateNamespace), but
lands in `default` under a raw `kubectl apply -f` without `-n`.

**Acceptance criteria:**
- `namespace: {{ .Values.namespace.name }}` added to the `mongo-init` ConfigMap.
- Namespace consistency holds across all rendered resources with no exception.

## REQ-argocd-app-name

- **source:** `STATUS.md` (PRD, prec 1) item F2
- **evidence:** `gsd/verifications/2026-08-03-helm-template-render.md` finding 6 (`argocd-app.yaml` lines 20-21); `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` R7; `gsd/repo-feedback/2026-08-03-org-delta-summary.md` F2
- **owner:** David Rubin — **routable: yes**
- **severity:** major (🟠) · **verified:** yes

`argocd-app.yaml` `Application.metadata` has a duplicate `name:` key
(`name: sports-store` then `name: cloudcart`). YAML last-wins → the Application is named
`cloudcart`. The `AppProject` is correctly named `sports-store`.

**Acceptance criteria:**
- Duplicate `name:` key removed; Application named `sports-store`.
- One-line correction on a dedicated branch.

**Severity note:** the risk scan and feedback note both grade this ℹ️ informational /
cosmetic ("sync itself should still function"), while `STATUS.md` grades it 🟠 major.
`STATUS.md` holds higher precedence, so 🟠 is recorded. This is a severity difference, not
a factual contradiction — the defect description is identical in all four sources.

## REQ-frontend-chart-intent

- **source:** `STATUS.md` (PRD, prec 1) item F6
- **evidence:** `gsd/verifications/2026-08-03-helm-template-render.md` extra observations; `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` resource inventory; `gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md` R8
- **owner:** David / team — **routable: BLOCKED ON DECISION**
- **severity:** major (🟠) per STATUS; ℹ️ per feedback note

No Deployment and no Service render for the frontend. `environments/production/images.yaml`
defines a `frontend` image tag, but `frontend` is not in `.Values.services`, so the chart
deploys 6 backend/gateway workloads only. The public storefront is served outside this
chart.

**⚠ COMPETING ACCEPTANCE VARIANTS — not merged, user must choose.**
See `INGEST-CONFLICTS.md` WARNING 2.

- **Variant A — frontend is deliberately not chart-managed.** Acceptance: the intent is
  documented, the stray `frontend` entry in `images.yaml` is reconciled or explained, and
  the item closes with no workload added.
- **Variant B — frontend should be chart-managed.** Acceptance: `frontend` added to
  `.Values.services`; Deployment and Service render; routing/ingress implications resolved.

No document in the set picks a variant. `STATUS.md` says "Intent must be confirmed with the
team and the chart aligned to that decision" — it defers rather than deciding. The two
variants imply materially different amounts of work and cannot be collapsed.

## REQ-secrets-reference-only

- **source:** `STATUS.md` (PRD, prec 1) item SECRETS
- **owner:** David Rubin — **routable: standing constraint, not a phase**
- **severity:** standing · **verified:** yes

Secrets stay reference-only in git; any leaked value is an immediate fix. Recorded as a
requirement in `STATUS.md` but functionally a permanent guardrail — see `constraints.md`
C-3. Should be treated as an invariant checked by every phase, not a phase of its own.

## REQ-refresh-local-from-main

- **source:** `gsd/repo-feedback/2026-08-03-org-delta-summary.md` (DOC) item F5
- **owner:** David Rubin — **routable: yes (housekeeping)**
- **severity:** immediate

Merge/rebase `docs/helm-secret-bootstrap` onto post-restructure `main` (#17/#18) before
further deployment work; commit pending `STATUS.md`/`GSD.md`/coordinator docs on the
current base first.

**Status caveat:** `STATUS.md` snapshot reports the active branch as
`gsd/post-merge-full-risk-scan` **in sync with `main`**, which suggests F5 may already be
satisfied. `STATUS.md` outranks the org-delta summary, so verify before routing this as
live work.

## REQ-readme-accuracy *(derived — not asserted by any source doc)*

- **derived from:** conflict between `README.md` (DOC) and `STATUS.md` (PRD, prec 1)
- **owner:** David Rubin (docs are David-owned per D-4) — **routable: after WARNING 1 resolved**
- **severity:** to be set by user

**This requirement was not stated by any document.** It is inferred from the README
staleness conflict and is flagged as derived so the roadmapper does not mistake it for
source-asserted intent. `README.md` documents a Stage 3 starter state (inline `TODO`
placeholders, `k8s/` per-service directories, standalone `helm install mongodb`) that
predates the Helm-umbrella + Argo CD + ESO structure recorded in `STATUS.md`. See
`INGEST-CONFLICTS.md` WARNING 1 for which parts are stale and which remain live.

---

# Not routable in this repo (track only)

These are real, tracked work items in `STATUS.md`, but `constraints.md` C-1 forbids them
becoming phases here. Listed so the roadmapper can see them and deliberately exclude them.

## REQ-eso-secrets-backend — owner: **Sean** — routable: **no**

- **source:** `STATUS.md` (PRD, prec 1) item R3 · severity critical (🔴) · cross-team blocker

`app-secrets` and Mongo URIs come from AWS Secrets Manager `sports-store/production` via
ESO, using IRSA `sports-store-external-secrets-role` in `us-east-1`. `ExternalSecret/app-secrets-eso`
carries `JWT_SECRET` plus the five `*_MONGO_URI` properties, `refreshInterval: 1h`.
Missing ESO operator, secret, properties, or IRSA → `app-secrets` never created → pods not
ready → ALB 503 → demo fails. All `*_MONGO_URI` values must resolve
`sports-store-mongodb:27017`. The chart cannot self-verify this.

David tracks only. This is the single highest-severity open item in the set and it is
**not David's to fix**.

## REQ-metrics-endpoints — owner: **Daniel Rusman** — routable: **no**

- **source:** `STATUS.md` (PRD, prec 1) item R5 · severity tracked/major

`/metrics` must be exposed on the services' `http` ports. ServiceMonitor endpoint is
`port: http`, `path: /metrics`; gateway listens on 8080 (Service 80→8080). Tracked via
`fix/ci-instrumentator` PRs. Pairs with REQ-servicemonitor-label-match.

## REQ-sean-infra — owner: **Sean** — routable: **no**

- **source:** `STATUS.md` (PRD, prec 1) item SEAN-INFRA · severity tracked

AWS Load Balancer Controller install; EBS StorageClass needed for REQ-mongodb-persistence;
implementation of the declared required extension (`sports-store-infrastructure` #6,
declared but not verified).

## REQ-mongo-password-property — owner: **Sean** — routable: **no**

- **source:** `gsd/verifications/2026-08-03-post-merge-full-risk-scan.md` R6; `gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md` R6 · severity informational

`mongodb-credentials-eso` maps both `mongodb-root-password` and `mongodb-passwords` from
the single `MONGO_ROOT_PASSWORD` property — functional, but root password equals user
password. Secret design decision for Sean.

**Gap note:** this item appears in two DOC sources but is **absent from `STATUS.md`'s open
lists**. Recorded here for completeness; see `INGEST-CONFLICTS.md` INFO 9.

## REQ-e2e-verification — owner: **cross-team** — routable: **no**

- **source:** `STATUS.md` (PRD, prec 1) item E2E · severity constraint · **not verified**

Frontend → gateway → each API → data layer is unproven. No API/demo-flow evidence has been
collected. Frontend/domain reachability is only a status signal and must never be
conflated with E2E in any report (see `decisions.md` D-6).
