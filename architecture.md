# Architecture

## Overview

This stack follows the standard Prometheus pull-based monitoring model. Each component runs as a dedicated systemd service on a single Ubuntu host.

---

## Component Breakdown

### Node Exporter (Port 9100)

Runs as a dedicated system user (`node_exporter`) with no login shell — a Linux security best practice for service accounts. Exposes hundreds of kernel and hardware metrics at `/metrics` in Prometheus text format.

Key metrics exposed:
- `node_cpu_seconds_total` — CPU usage per mode (user, system, idle, iowait)
- `node_memory_MemAvailable_bytes` — available RAM
- `node_disk_io_time_seconds_total` — disk I/O saturation
- `node_network_receive_bytes_total` — network throughput

### Prometheus (Port 9090)

Scrapes Node Exporter every 15 seconds and stores the data as time-series in its local TSDB (Time Series Database) at `/opt/prometheus/data`. Also scrapes itself for self-monitoring.

Config decisions:
- `scrape_interval: 15s` — standard for infrastructure monitoring
- `--web.listen-address=0.0.0.0:9090` — binds to all interfaces, avoids IPv6-only binding issue
- Separate `job_name` entries for clean target labelling in Grafana

### Grafana (Port 3000)

Connects to Prometheus as a data source and renders dashboards. Uses `http://127.0.0.1:9090` (loopback) rather than `localhost` to avoid DNS resolution issues in some environments.

---

## Data Flow

```
Linux Kernel / Hardware
        │
        ▼
  Node Exporter
  /opt/node_exporter/node_exporter
  Listens: 0.0.0.0:9100
  Runs as: node_exporter (no-login user)
        │
        │  HTTP GET /metrics (every 15s)
        ▼
  Prometheus
  /opt/prometheus/prometheus
  Listens: 0.0.0.0:9090
  Stores:  /opt/prometheus/data (TSDB)
        │
        │  PromQL queries
        ▼
  Grafana
  Listens: 0.0.0.0:3000
  Reads:   http://127.0.0.1:9090
```

---

## systemd Service Design

All three services are managed by systemd with `Restart=always` (Prometheus) and `WantedBy=multi-user.target`, meaning they start automatically on boot and restart on failure.

Node Exporter runs under a dedicated unprivileged user rather than root — standard security practice for any long-running service that doesn't require elevated privileges.

---

## Why This Matters in Production

This architecture mirrors how observability is implemented in production environments:

- **Pull-based scraping** — Prometheus pulls metrics rather than agents pushing them, making it easier to detect when a target goes silent
- **Dedicated service accounts** — isolates blast radius if a service is compromised
- **systemd management** — consistent with how production Linux services are operated and monitored
- **Separation of concerns** — collection (Node Exporter), storage (Prometheus), and visualisation (Grafana) are independent and replaceable
