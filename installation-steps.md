# Installation Steps

Manual step-by-step guide to set up the full monitoring stack on Ubuntu.

---

## Prerequisites

- Ubuntu Linux (20.04 or 22.04 recommended)
- `sudo` access
- Internet connection

---

## Step 1 — Install Node Exporter

```bash
sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter

cd /opt
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.0/node_exporter-1.9.0.linux-amd64.tar.gz

tar xvf node_exporter-1.9.0.linux-amd64.tar.gz

sudo mv node_exporter-1.9.0.linux-amd64 node_exporter
```

---

## Step 2 — Create Node Exporter systemd Service

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

Paste the contents of `node_exporter/node_exporter.service` from this repo.

```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

Verify:

```bash
systemctl status node_exporter
curl http://localhost:9100/metrics | head -20
```

---

## Step 3 — Install Prometheus

```bash
cd /opt
wget https://github.com/prometheus/prometheus/releases/download/v3.9.1/prometheus-3.9.1.linux-amd64.tar.gz

tar xvf prometheus-3.9.1.linux-amd64.tar.gz

sudo mv prometheus-3.9.1.linux-amd64 prometheus
```

---

## Step 4 — Configure Prometheus

Copy the config file from this repo:

```bash
sudo cp prometheus/prometheus.yml /opt/prometheus/prometheus.yml
```

Or create it manually at `/opt/prometheus/prometheus.yml` with the contents from `prometheus/prometheus.yml`.

---

## Step 5 — Create Data Directory

```bash
mkdir /opt/prometheus/data
sudo chown -R $USER:$USER /opt/prometheus/data
```

---

## Step 6 — Create Prometheus systemd Service

```bash
sudo nano /etc/systemd/system/prometheus.service
```

Paste the contents of `prometheus/prometheus.service` from this repo.

```bash
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
```

Verify:

```bash
systemctl status prometheus
curl http://localhost:9090/-/healthy
```

---

## Step 7 — Install Grafana

```bash
sudo apt-get install -y apt-transport-https software-properties-common wget

sudo mkdir -p /etc/apt/keyrings/

wget -q -O - https://apt.grafana.com/gpg.key | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | \
  sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update
sudo apt install grafana -y
```

---

## Step 8 — Start Grafana

```bash
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

Access at `http://localhost:3000` — default credentials: `admin / admin`

---

## Step 9 — Add Prometheus as a Grafana Data Source

1. Log in to Grafana
2. Go to **Connections → Data Sources → Add data source**
3. Select **Prometheus**
4. Set URL to `http://127.0.0.1:9090`
5. Click **Save & Test** — should show green

---

## Step 10 — Import a Dashboard

1. Go to **Dashboards → Import**
2. Enter dashboard ID `1860` (Node Exporter Full — community dashboard)
3. Select your Prometheus data source
4. Click **Import**

You should now see live CPU, memory, disk, and network metrics.
