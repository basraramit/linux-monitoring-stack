# Troubleshooting Notes

Real errors encountered during setup and how they were resolved.

---

## Problem 1 — Exec Format Error

### Error

```
cannot execute binary file: Exec format error
```

### Root Cause

Downloaded the wrong architecture binary (e.g. `darwin` or `arm64` instead of `linux-amd64`).

### Fix

Download the correct binary for your system:

```bash
# Verify your architecture first
uname -m
# x86_64 → use linux-amd64
# aarch64 → use linux-arm64
```

Then download the matching release from GitHub.

---

## Problem 2 — Duplicate static_configs

### Error

```
field static_configs already set in type config.ScrapeConfig
```

### Root Cause

The `prometheus.yml` had two separate `static_configs` blocks under the same `job_name`.

### Fix

Combine all targets under a single `static_configs` block:

```yaml
# ❌ Wrong
scrape_configs:
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]
    static_configs:
      - targets: ["localhost:9090"]

# ✅ Correct
scrape_configs:
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
```

Validate the config after any changes:

```bash
/opt/prometheus/promtool check config /opt/prometheus/prometheus.yml
```

---

## Problem 3 — Permission Denied on Data Directory

### Error

```
unable to create mmap-ed active query log
```

### Root Cause

The `/opt/prometheus/data` directory was owned by root but Prometheus was running as a non-root user.

### Fix

```bash
sudo chown -R $USER:$USER /opt/prometheus/data
```

Then restart:

```bash
sudo systemctl restart prometheus
```

---

## Problem 4 — Prometheus Binding on IPv6 Only

### Symptom

Prometheus was accessible at `http://[::]:9090` but not at `http://localhost:9090` or the machine's IP.

### Root Cause

Default listen address was binding to IPv6 only on some Ubuntu configurations.

### Fix

Explicitly set the listen address to `0.0.0.0` in the service file:

```ini
ExecStart=/opt/prometheus/prometheus \
  --config.file=/opt/prometheus/prometheus.yml \
  --storage.tsdb.path=/opt/prometheus/data \
  --web.listen-address=0.0.0.0:9090
```

Then reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart prometheus
```

Verify it's listening correctly:

```bash
sudo ss -tulnp | grep 9090
```

---

## General Diagnostic Commands

```bash
# Check service status
systemctl status prometheus
systemctl status node_exporter

# View live logs
journalctl -u prometheus -f
journalctl -u node_exporter -f

# Check what ports are listening
sudo ss -tulnp

# Test Node Exporter is responding
curl http://localhost:9100/metrics | head -10

# Test Prometheus is healthy
curl http://localhost:9090/-/healthy
```
