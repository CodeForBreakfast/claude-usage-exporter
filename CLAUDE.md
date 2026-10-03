# claude-usage-exporter

## What claude-usage-exporter owns

claude-usage-exporter is a Prometheus and OpenTelemetry exporter for Claude.ai
session and weekly usage. It polls the Claude.ai usage API for each configured
account and exposes the results as metrics.

This repo decides and changes:

- The metric names, types, units and labels, including `org_id` as the join key
  to Claude Code metrics.
- The adaptive polling behaviour and its defaults.
- The `accounts.yaml` schema and the environment variables the exporter reads.
- The example config, the Docker image, the Nix build and the Compose quickstart.
- The bundled Grafana dashboard, the Prometheus config and the alert rules.

## What it does not own

- **A user's credentials and accounts.** The `sessionKey` and `orgId` values
  and the `accounts.yaml` that holds them belong to whoever runs the exporter.
  The repo ships only an example file with placeholders.
- **A user's deployment.** Where the exporter runs, its scrape config, its
  dashboards in use and its alert routing belong to whoever runs it.
- **Prometheus, Grafana and any OTLP collector.** The bundled configs are
  examples. The running services belong to whoever operates them.
- **The Claude.ai usage API.** It is an undocumented web endpoint run by
  Anthropic. Changes to it are reported upstream or absorbed here, and never
  worked around by changing what the metrics mean.
- **Claude Code's own telemetry.** The metrics Claude Code emits belong to
  Claude Code. This repo only shares the `org_id` key with them.

A seat may decline an ask that falls outside this remit, and says where the ask
belongs.
