# Research — Team status update (org sweep + domain)

_Date: 2026-08-03 · Branch: `docs/helm-secret-bootstrap`_

Documentation-only capture of the latest team updates from Maxim (org sweep) and
Sean (public domain). No code, Helm, or Terraform changes made here.

## Sources

- **Maxim** — full organization sweep, 2026-08-03.
- **Sean** — public domain reachability check.

## Findings

### Resolved

- `:latest` tag issue fixed across all **7** image repositories.

### Security blocker — OIDC regression (owner: infra / CI owners)

CI/CD push-to-ECR workflows moved from an OIDC `role-to-assume` to **long-lived
static AWS keys**:

```yaml
aws-access-key-id: secrets.AWS_ACCESS_KEY_ID
aws-secret-access-key: secrets.AWS_SECRET_ACCESS_KEY
```

This violates the project brief, which mandates AWS auth via OIDC / short-lived
federated credentials, not static keys. Classified as a **cross-repo security
blocker**. Remediation (revert to OIDC) is owned by the CI/infra owners and is
**outside David's deployments/docs scope**. Recorded for visibility only.

### Argo CD / GitOps gaps (owner: infra / GitOps owners; David advisory)

- No `AppProject` defined.
- No `environments/` or per-service image files.
- Argo CD config appears to sit under `sports-store-infrastructure` rather than
  `sports-store-deployments`.
- Namespace mismatch persists: `cloudcart` vs `sports-store`.

### Terraform naming leftovers (owner: infra owners)

Stale references (`FraudstersList`, `FifaApp`) remain in `argocd.tf`,
`prometheus.tf`, `pod-identity.tf`, `secrets.tf`, `tfc-oidc.tf`.

### Observability gaps (owner: infra owners)

- Alertmanager disabled.
- Grafana auth config not visible.

### Deployment-layer item (owner: David — investigate later)

`helm template` still renders the `app-secrets` Secret with **empty `stringData`**.
This is a deployment-layer blocker for David to **investigate later**, not to fix in
this docs task. No Helm edits and no secret values are introduced here.

### Project brief

Required extension is still **not formally declared**.

## Sean — domain reachability

- Public URL: https://sportsstore.seansite.org/
- The page loads and renders the Stryda Athletics storefront.

**Interpretation:** confirms **frontend / gateway / domain reachability only**. It is
**not** full end-to-end API validation. E2E (frontend → gateway → APIs → data layer)
stays **unverified** until proven with API-level checks. `STATUS.md` keeps these two
levels explicitly separate.

## Scope note (David)

David's scope is **deployments / Helm / GitOps / docs only**. The OIDC regression,
Terraform, IAM, and observability items are owned by infra/CI owners and are tracked
here for coordination, not for David to action.

## Follow-ups

- Coordinate with infra/CI owners on the OIDC revert (they own it).
- Later: investigate the Helm `app-secrets` empty-render on its own branch.
- Later: advise on Argo CD structure/namespace alignment where it overlaps deployments.
