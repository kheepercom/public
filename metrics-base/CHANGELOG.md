# Changelog

## v0.1.1

### Changes

- Rebuild on `base` v0.1.1 (latest `fedora-bootc:44` digest)

## v0.1.0

### Features

- VictoriaMetrics single-node on `127.0.0.1:8428` with 30-day retention
- `node_exporter` on `127.0.0.1:9100`, scraped by vmsingle
- Drop-in scrape extension via `/etc/victoria-metrics/scrape.d/*.json`, reloaded every 30s
- Grafana on `127.0.0.1:3000` with VictoriaMetrics datasource and a starter "Node Overview" dashboard
- Drop-in dashboard extension via `/etc/grafana/dashboards/`, auto-loaded every 30s
- Pinned `vmetrics` and `grafana` system UIDs/GIDs for stable ownership across rebuilds
