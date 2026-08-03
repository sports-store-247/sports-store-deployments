# Verification — `helm template` render of `helm/sports-store`

_Date: 2026-08-03 · Documentation + verification only · No Helm/Terraform/app edits._

## Method

The working tree is on `docs/helm-secret-bootstrap` (14 commits behind `main`) and does
**not** contain the restructured chart. To verify the **`main`** chart without editing
the repo, creating a branch, or checking out, the chart + `argocd-app.yaml` were exported
from `origin/main` to a scratch dir and rendered there:

```
git archive origin/main helm/sports-store argocd-app.yaml | tar -x -C <scratch>
helm template sports-store <scratch>/helm/sports-store -n sports-store \
  -f environments/production/values.yaml \
  -f environments/production/images.yaml
```

- helm: `v4.2.1`
- Result: **exit 0**, no stderr, 1327 lines rendered. MongoDB dependency (Bitnami,
  vendored `charts/mongodb-16.5.20.tgz`) rendered offline.

Rendered object inventory (kind → name):

```
Namespace           -> sports-store
ConfigMap           -> auth-config, cart-config, order-config, payment-config, mongo-init, sports-store-mongodb-common-scripts
Deployment          -> auth-service, cart-service, catalog-service, gateway, order-service, payment-service, sports-store-mongodb
Service             -> auth-service, cart-service, catalog-service, gateway, order-service, payment-service, sports-store-mongodb
Ingress             -> sports-store-gateway
ExternalSecret      -> app-secrets-eso, mongodb-credentials-eso
SecretStore         -> aws-secrets-manager
ServiceAccount      -> app-secrets-sa, sports-store-mongodb
NetworkPolicy / PDB -> sports-store-mongodb
```

---

## Findings (verified against rendered output)

### 1. Does the ServiceMonitor render? — **NO** ❌
`grep -c "kind: ServiceMonitor"` on the rendered output = **0**. No ServiceMonitor is
emitted, even with the production values files applied.

### 2. `.Values.microservices` vs `.Values.services` mismatch? — **YES, confirmed root cause** 🟠
- `values.yaml` defines a top-level **`services:`** map (line 10). There is **no**
  `microservices:` key.
- `templates/servicemonitor.yaml` line 1: `{{- range .Values.microservices }}` — ranges
  over an **undefined** key, so the block iterates zero times → nothing renders.
- `templates/services.yaml` and `templates/deployments.yaml` both range over
  `.Values.services` (correct). So the ServiceMonitor is the **only** template using the
  wrong key. This is the direct cause of finding #1 — a **silent observability no-op**.

### 3. Exact image tags that resolve — **all `0.1.0-latest`**
Deployable application images (from `environments/production/images.yaml` +
`values.yaml`), registry `765858872029.dkr.ecr.us-east-1.amazonaws.com`:

| Service | Rendered image |
|---------|----------------|
| auth-service | `…/sports-store-auth-service:0.1.0-latest` |
| cart-service | `…/sports-store-cart-service:0.1.0-latest` |
| catalog-service | `…/sports-store-catalog-service:0.1.0-latest` |
| gateway | `…/sports-store-gateway:0.1.0-latest` |
| order-service | `…/sports-store-order-service:0.1.0-latest` |
| payment-service | `…/sports-store-payment-service:0.1.0-latest` |
| MongoDB (subchart) | `docker.io/library/mongo:8.0` (not `latest` — OK) |

### 4. Any image using `latest` / `0.1.0-latest`? — **YES** 🔴
All **6** rendered application Deployments resolve to `:0.1.0-latest`. This **violates the
brief** (`<semver>-<7-char-git-hash>`, and no `latest` anywhere for deployable images).
`0.1.0-latest` is not a git-hash tag and contains the literal `latest`. Confirms F1 at the
**deployment layer** — independent of the service-repo CI fix. (MongoDB `mongo:8.0` is fine.)

### 5. Is gateway the only Ingress? — **YES** ✅ (but backend name is broken — see #7)
Exactly **1** `kind: Ingress` renders: `sports-store-gateway`, host
`sportsstore.seansite.org`, `ingressClassName: alb`, with AWS ALB annotations
(internet-facing, ACM cert, health-check `/health`). No other service gets an Ingress.
Gateway is the only external entrypoint — brief-compliant in intent.

### 6. Argo CD Application duplicate `name` keys? — **YES** 🟠
`argocd-app.yaml` `Application.metadata`:
```
20:  name: sports-store
21:  name: cloudcart
```
Duplicate mapping key; YAML last-wins → the **Application is named `cloudcart`**. (The
`AppProject` is correctly named `sports-store`.) This is the `cloudcart` vs `sports-store`
naming mismatch resurfacing at the GitOps layer. Confirms F2.

### 7. `ingress.yaml` duplicate `service.name` keys? — **YES, and it breaks routing** 🔴 (elevated)
`templates/ingress.yaml` backend block:
```
23:  name: gateway
24:  name: {{ $.Release.Name }}-gateway
```
Duplicate key → last-wins. Rendered backend resolves to `service.name: sports-store-gateway`.
**But the actual gateway Service is named `gateway`** (rendered `Service -> gateway`,
ClusterIP, port 80). So the Ingress points at a Service (`sports-store-gateway`) that
**does not exist**. This is **not cosmetic** — the ALB target would fail to resolve its
backend. Previously logged as F3 (cosmetic); this render **upgrades it to a functional
routing defect**.

---

## Extra observations (verified)

- **Frontend renders no workload.** `environments/production/images.yaml` defines a
  `frontend` image tag, but **no Deployment and no Service for frontend render**
  (`grep -c sports-store-frontend` = 0). Frontend is not part of `.Values.services`, so
  the chart deploys 6 backend/gateway services only. The public storefront is served
  outside this chart. David-owned observation — confirm whether frontend is intended to
  be chart-managed.
- **ESO restructure confirmed rendering:** `ExternalSecret/app-secrets-eso`,
  `ExternalSecret/mongodb-credentials-eso`, `SecretStore/aws-secrets-manager`, and
  `ServiceAccount/app-secrets-sa` all render — the old empty `secret.yaml` is gone. Whether
  these resolve at runtime depends on Sean's AWS Secrets Manager + IRSA backend (not
  verifiable from a template render).

---

## Summary table

| # | Check | Result |
|---|-------|--------|
| 1 | ServiceMonitor renders | ❌ No (0 emitted) |
| 2 | `microservices` vs `services` mismatch | 🟠 Yes — root cause of #1 |
| 3 | Resolved image tags | `0.1.0-latest` (6 services) |
| 4 | Uses `latest`/`0.1.0-latest` | 🔴 Yes — brief violation |
| 5 | Only gateway gets Ingress | ✅ Yes |
| 6 | Argo CD Application duplicate `name` | 🟠 Yes → app named `cloudcart` |
| 7 | Ingress duplicate `service.name` | 🔴 Yes → points to non-existent `sports-store-gateway` |

## Boundary
Template render only. Not applied to a cluster; **E2E is not verified**. Domain
reachability remains a status signal, not proof of end-to-end function.
