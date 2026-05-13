#!/bin/bash
# install_prometheus.sh
# Installs Prometheus v3.9.1 as a systemd service on Ubuntu/Debian

set -e

PROMETHEUS_VERSION="3.9.1"
INSTALL_DIR="/opt/prometheus"
SERVICE_FILE="/etc/systemd/system/prometheus.service"
CONFIG_SOURCE="$(dirname "$0")/../prometheus/prometheus.yml"

echo "==> Downloading Prometheus v${PROMETHEUS_VERSION}..."
cd /tmp
wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

echo "==> Extracting..."
tar xvf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

echo "==> Installing to ${INSTALL_DIR}..."
sudo mv "prometheus-${PROMETHEUS_VERSION}.linux-amd64" "${INSTALL_DIR}"

echo "==> Creating data directory..."
sudo mkdir -p "${INSTALL_DIR}/data"
sudo chown -R "$USER":"$USER" "${INSTALL_DIR}/data"

echo "==> Copying prometheus.yml config..."
if [ -f "${CONFIG_SOURCE}" ]; then
  sudo cp "${CONFIG_SOURCE}" "${INSTALL_DIR}/prometheus.yml"
else
  echo "Warning: prometheus.yml not found at ${CONFIG_SOURCE}, using existing config."
fi

echo "==> Writing systemd service file..."
sudo tee "${SERVICE_FILE}" > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/prometheus \\
  --config.file=${INSTALL_DIR}/prometheus.yml \\
  --storage.tsdb.path=${INSTALL_DIR}/data \\
  --web.listen-address=0.0.0.0:9090
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "==> Enabling and starting Prometheus..."
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

echo ""
echo "✅ Prometheus installed successfully."
echo "   Status:    systemctl status prometheus"
echo "   Dashboard: http://localhost:9090"
echo "   Validate config: ${INSTALL_DIR}/promtool check config ${INSTALL_DIR}/prometheus.yml"
