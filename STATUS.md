# STATUS — Sports Store Deployments

Live project dashboard. Process rules live in [`GSD.md`](./GSD.md); this file tracks
**current state** only.

_Last updated: 2026-08-03_

---

## Snapshot

| Field | Value |
|-------|-------|
| Stage | Stage 3 — Local Kubernetes + Helm umbrella |
| Namespace | `sports-store` |
| Active branch | `docs/helm-secret-bootstrap` |
| Default branch | `main` (PR-gated, 1 approval required) |
| Helm chart | `helm/sports-store` (umbrella) |

---

## Components

| Component | Where | State |
|-----------|-------|-------|
| Namespace | `namespace.yaml` | defined |
| Secrets | `secrets/` | referenced via existingSecret, no values in git |
| ConfigMaps | `configmaps/` | present |
| MongoDB (Bitnami) | `mongodb/`, `helm/sports-store` | seeded via `mongo-init` configmap |
| auth / catalog / cart / order / payment | service dirs | manifests present |
| Gateway | `gateway/` | only externally reachable service |

---

## Recent activity

- `fix(helm): deploy mongo-init configmap to release namespace` (#14)
- `feat(helm): add mongo-init configmap to seed database` (#13)
- `fix(helm): secure mongodb auth by referencing secret` (#12)
- `fix(helm): add mongo init env vars for authentication` (#11)

---

## In progress

- **Docs bootstrap** (`docs/helm-secret-bootstrap`) — split process vs. status into
  `GSD.md` + `STATUS.md`, scaffold `gsd/` work folders.
  See [research note](./gsd/research/2026-08-03-docs-bootstrap.md).

---

## Next up

- [ ] Wire secret bootstrap docs into the Helm deploy flow.
- [ ] First verification note under `gsd/verifications/` for the MongoDB seed.
- [ ] Confirm gateway is the only externally exposed Service.

---

## Known issues / watch

- Secrets must stay reference-only in git. Any leaked value is an immediate fix.
- MongoDB must be healthy before app Deployments connect cleanly.
