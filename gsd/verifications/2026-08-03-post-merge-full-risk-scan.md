# Verification — Post-merge full risk scan (deployments / Helm / GitOps)

_Date: 2026-08-03 · Branch: `gsd/post-merge-full-risk-scan` (in sync with `main`) ·
Documentation + verification only. No Helm/Terraform/app/CI edits. E2E NOT claimed._

## Method

```
helm lint ./helm/sports-store
helm template sports-store ./helm/sports-store --namespace sports-store \
  -f ./helm/sports-store/environments/production/values.yaml \
  -f ./helm/sports-store/environments/production/images.yaml
```

- **helm lint** → `1 chart(s) linted, 0 chart(s) failed` (only `icon is recommended` INFO).
- **helm template** → **exit 0**, 1519 lines, no stderr. MongoDB (Bitnami) rendered offline.

---

## [3] Resource inventory (kind | name | namespace)

| Kind | Name | Namespace |
|------|------|-----------|
| Namespace | sports-store | — |
| ServiceAccount | sports-store-mongodb | sports-store |
| ServiceAccount | app-secrets-sa | sports-store (IRSA annotated) |
| NetworkPolicy / PDB | sports-store-mongodb | sports-store |
| ConfigMap | auth/cart/order/payment-config | sports-store |
| ConfigMap | sports-store-mongodb-common-scripts | sports-store |
| ConfigMap | **mongo-init** | **(blank — see R4)** |
| Service | sports-store-mongodb | sports-store |
| Service | auth/cart/catalog/gateway/order/payment-service | sports-store |
| Deployment | sports-store-mongodb | sports-store |
| Deployment | auth/cart/catalog/gateway/order/payment-service | sports-store |
| Ingress | sports-store-gateway | sports-store |
| ExternalSecret | app-secrets-eso, mongodb-credentials-eso | sports-store |
| SecretStore | aws-secrets-manager | sports-store |
| ServiceMonitor | sports-store-{auth,cart,catalog,gateway,order,payment}-service | sports-store |

Frontend: no Deployment/Service renders (not in `.Values.services`) — unchanged from prior scan.

---

## Verified PASS

- **[1] Lint** — pass.
- **[2] Render** — exit 0, namespace-aware.
- **[4] Namespace consistency** — Namespace, MongoDB, all Services, all Deployments,
  Ingress, both ExternalSecrets, SecretStore, all ServiceMonitors render in
  `sports-store`. **One exception:** `ConfigMap/mongo-init` (R4).
- **[5] Ingress backend** — `service.name: gateway`, `port.number: 80`, namespace
  `sports-store`. Matches the rendered `Service/gateway` (ClusterIP, port 80). **F3 stays
  fixed.**
- **[7] MongoDB service** — `Service/sports-store-mongodb`, port **27017**. In-cluster DNS
  `sports-store-mongodb.sports-store.svc:27017`. App `MONGO_URI`s are injected from the
  `app-secrets` Secret (see R3) — the host string itself lives in AWS Secrets Manager, not
  the chart.
- **[8] Image tags** — all 6 app images are `0.1.0-<7char-hash>`
  (auth `686e7cd`, cart `6e0f5cc`, catalog `06243ee`, gateway `11ea172`, order `1661894`,
  payment `2738bd5`); MongoDB `mongo:8.0`. **No `latest` / `0.1.0-latest`.** F1 resolved.
- **[9] ESO internal wiring consistent** — `app-secrets-eso` target Secret is `app-secrets`;
  every app Deployment `secretKeyRef.name` is `app-secrets`. Names match.

---

## Findings / risks

### R1 — ServiceMonitor selectors do NOT match Service labels → metrics not scraped 🔴 — **David-owned**
- ServiceMonitor `sports-store-gateway` `spec.selector.matchLabels`:
  `app.kubernetes.io/name: gateway`, `app.kubernetes.io/instance: sports-store`.
- Rendered `Service/gateway` labels: `app: gateway`,
  **`app.kubernetes.io/name: sports-store`** (chart name, from the shared
  `sports-store.labels` helper), `app.kubernetes.io/instance: sports-store`.
- The Service's `app.kubernetes.io/name` is `sports-store`, **not** `gateway`, so the
  selector matches **no** Service. Applies to all 6 ServiceMonitors → **Prometheus scrapes
  nothing.** Root cause: mismatch between the per-service ServiceMonitor selector and the
  helper-provided Service labels. (Metrics-not-scraped.)

### R2 — MongoDB data is `emptyDir` (no persistence) → data loss 🔴 — **David-owned**
- MongoDB renders as a **Deployment** (not StatefulSet); the `datadir` volume mounted at
  `/bitnami/mongodb` is **`emptyDir: {}`**. No PVC/volumeClaimTemplate renders.
- Data does **not** survive pod restart/reschedule/`helm upgrade`/rollback/uninstall, and
  the `mongo-init` seed re-runs on every restart. **Violates the brief** ("MongoDB
  persistent data should survive install/upgrade/rollback/uninstall"). (Mongo data loss;
  demo-fragile.)

### R3 — App secrets + Mongo URIs come from AWS Secrets Manager (runtime, unverifiable here) 🔴 — **cross-team blocker (Sean runtime)**
- `SecretStore/aws-secrets-manager`: provider `aws`, `service: SecretsManager`,
  `region: us-east-1`, auth via `serviceAccountRef: app-secrets-sa`.
- `ServiceAccount/app-secrets-sa` IRSA: `eks.amazonaws.com/role-arn:
  arn:aws:iam::765858872029:role/sports-store-external-secrets-role`.
- `ExternalSecret/app-secrets-eso` → Secret `app-secrets`, `refreshInterval: 1h`, remoteRef
  `key: sports-store/production`, properties: **JWT_SECRET, AUTH_MONGO_URI, CATALOG_MONGO_URI,
  CART_MONGO_URI, ORDER_MONGO_URI, PAYMENT_MONGO_URI**.
- `ExternalSecret/mongodb-credentials-eso` → Secret `mongodb-credentials`, properties
  `MONGO_ROOT_PASSWORD` (mapped to both `mongodb-root-password` and `mongodb-passwords`).
- **The chart cannot self-verify these resolve.** If the ESO operator, the Secrets Manager
  secret, the properties, or the IRSA role are missing/mis-scoped, the `app-secrets` Secret
  is never created → app `secretKeyRef` lookups fail → **pods not ready → ALB 503 → demo
  fails.** Also the `*_MONGO_URI` **values** must point to `sports-store-mongodb:27017` with
  the right auth db/credentials (Mongo resolution).

### R4 — `mongo-init` ConfigMap renders with no namespace 🟠 — **David-owned (low)**
- Unlike every other template, `mongo-init-configmap.yaml` omits
  `namespace: {{ .Values.namespace.name }}`. Under Argo CD (destination ns `sports-store`
  + CreateNamespace) it lands correctly; under a raw `kubectl apply -f` without `-n` it
  would go to `default`. Consistency risk, same class as the old F3 namespace bug.

### R5 — Metrics endpoint must actually exist on the pods 🟠 — **Daniel-owned**
- ServiceMonitor endpoint is `port: http`, `path: /metrics`. Gateway container listens on
  `8080` (Service `http` 80→8080). Even after R1 is fixed, each service image must expose
  `/metrics` on its `http` port. Relates to the open `fix/ci-instrumentator` PRs in the
  service repos. (Metrics-not-scraped, secondary.)

### R6 — Mongo root and user passwords share one source property ℹ️ — **Sean-owned (informational)**
- `mongodb-credentials-eso` maps both `mongodb-root-password` and `mongodb-passwords` from
  the same `MONGO_ROOT_PASSWORD` property. Functional, but root == user password. Secret
  design decision for Sean.

### R7 — Argo CD Application name is `cloudcart` (F2) ℹ️ — **David-owned (separate task)**
- `argocd-app.yaml` (repo root, not chart) still has duplicate `name:` → Application named
  `cloudcart`. Out of scope for this render; tracked separately. Sync itself should still
  function (project/namespace correct).

---

## [10] Risk → failure-mode mapping

| Failure mode | Cause(s) | Owner |
|--------------|----------|-------|
| **ALB 503** | Gateway pods unhealthy from missing `app-secrets` (R3) or Mongo unreachable (R2/R3); ALB controller must be installed | Sean (secrets/ALB) + Daniel (app health) |
| **Pods not ready** | `app-secrets` never synced (R3); app can't reach Mongo | Sean (R3) |
| **Missing secrets** | ESO operator / `sports-store/production` secret / IRSA role absent | Sean (R3) |
| **Mongo resolution failure** | `*_MONGO_URI` value ≠ `sports-store-mongodb:27017` / wrong auth (R3); data wiped each restart (R2) | Sean (URI values) + David (R2 persistence) |
| **Metrics not scraped** | ServiceMonitor selector mismatch (R1); `/metrics` endpoint missing (R5) | David (R1) + Daniel (R5) |
| **Argo CD sync problems** | ESO CRDs must exist before sync or Application health degrades; `mongo-init` ns (R4) | Sean (CRDs) + David (R4) |
| **Demo failure** | Compound of R2 + R3 (data/secrets) and R1 (empty dashboards) | cross-team |

---

## Boundary
Template render only; nothing applied to a cluster. **E2E is not verified.** Domain
reachability remains a status signal, not proof of end-to-end function.
