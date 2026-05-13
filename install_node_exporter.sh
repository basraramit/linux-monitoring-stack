#!/bin/bash
# install_node_exporter.sh
# Installs Node Exporter v1.9.0 as a systemd service on Ubuntu/Debian

set -e

NODE_EXPORTER_VERSION="1.9.0"
INSTALL_DIR="/opt/node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

echo "==> Creating node_exporter system user..."
sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter 2>/dev/null || echo "User already exists, skipping."

echo "==> Downloading Node Exporter v${NODE_EXPORTER_VERSION}..."
cd /tmp
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "==> Extracting..."
tar xvf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "==> Installing to ${INSTALL_DIR}..."
sudo mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64" "${INSTALL_DIR}"

echo "==> Writing systemd service file..."
sudo tee "${SERVICE_FILE}" > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=${INSTALL_DIR}/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "==> Enabling and starting Node Exporter..."
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo ""
echo "✅ Node Exporter installed successfully."
echo "   Status: systemctl status node_exporter"
echo "   Metrics: http://localhost:9100/metrics"
