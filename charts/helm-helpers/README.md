# helm-helpers

Library chart with the naming, label and version helpers shared by the
[`app`](https://github.com/iberico-lab/iberico-charts/blob/main/charts/app), `ingress` and `external-secrets` charts. It renders
nothing on its own.

Shared values (under `global:`): `name`, `fullnameOverride`,
`nameOverride`, `version`. See [Architecture](https://github.com/iberico-lab/iberico-charts/blob/main/docs/architecture.md).
