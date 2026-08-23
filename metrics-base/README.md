# metrics-base

`us.kheeper.com/public/metrics-base` — [`base`](../base) plus a self-contained single-node observability stack. Build `FROM` this instead of `base` when you want every host to be self-monitoring on first boot.

This image is meant to be layered, not booted directly.

## Configuration

Inherits `admin_authorized_keys` from [`base`](../base). No additional config fields are exposed.

## Ports

Inherits `22/tcp` from [`base`](../base). No additional ports are opened: vmsingle, `node_exporter`, and Grafana all bind to `127.0.0.1` only. Reach them by SSH-tunneling from a workstation (`ssh -L 8428:127.0.0.1:8428 admin@<host>` for vmui, `ssh -L 3000:127.0.0.1:3000 admin@<host>` for Grafana).

## Layering on this image

```Containerfile
FROM us.kheeper.com/public/metrics-base:v0.2.1

# drop a scrape config in /etc/victoria-metrics/scrape.d/<service>.json
# and a dashboard JSON in /var/lib/grafana/dashboards/ to extend the stack
```

## observability

[VictoriaMetrics single-node](https://docs.victoriametrics.com/) (`vmsingle`) runs on `127.0.0.1:8428`, scraping itself and a co-located [`node_exporter`](https://github.com/prometheus/node_exporter) on `127.0.0.1:9100`.

vmsingle stores 30 days of metrics at `/var/lib/victoria-metrics` and re-reads its scrape config every 30 seconds, so child images can extend the dashboard without restarting anything: drop a single `/etc/victoria-metrics/scrape.d/<service>.json` file containing one file_sd target with a `labels.job` key and the new exporter is picked up within a scrape interval. Both observability services run as a dedicated locked-down `vmetrics` system user.

[Grafana](https://grafana.com/) runs on `127.0.0.1:3000` with the VictoriaMetrics datasource and a starter "Node Overview" dashboard provisioned from files baked into the image (`/etc/grafana/provisioning/`, `/var/lib/grafana/dashboards/`). Log in as `admin`/`admin` (Grafana forces a password change on first login). Add more dashboards by dropping JSON files in `metrics-base/grafana-dashboards/` — they auto-load every 30 seconds.
