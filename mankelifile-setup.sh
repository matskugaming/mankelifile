#!/bin/bash
set -e

SERVICE_NAME="mankelifile"
BASE_DIR="/opt/mankelifile"
INSTALLER_URL="https://vd.varmasti.xyz/api/mankelifile-installer"
INSTALLER_FILE="$BASE_DIR/install.php"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

echo "== MankeliFile installer =="
echo

# Ask for port
read -p "Enter port for server: " PORT
PORT=${PORT:-8000}

# Validate port (basic check)
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Invalid port."
    exit 1
fi

# 1. Create directory
echo "[1/6] Creating directory $BASE_DIR"
mkdir -p "$BASE_DIR"

# 2. Download installer
echo "[2/6] Downloading installer"
curl -fsSL "$INSTALLER_URL" -o "$INSTALLER_FILE"

# 3. Set permissions
echo "[3/6] Setting permissions"
chown -R www-data:www-data "$BASE_DIR"
chmod 755 "$INSTALLER_FILE"

# 4. Create systemd service
echo "[4/6] Creating systemd service"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Simple PHP File Server on port $PORT
After=network.target

[Service]
Type=simple
WorkingDirectory=$BASE_DIR
ExecStart=/usr/bin/php -S 0.0.0.0:$PORT -t $BASE_DIR
Restart=always
RestartSec=3
User=www-data
Group=www-data

StandardOutput=append:/var/log/mankelifile.log
StandardError=append:/var/log/mankelifile.log

[Install]
WantedBy=multi-user.target
EOF

# 5. Enable & start service
echo "[5/6] Enabling and starting service"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# 6. Output installer link
IP=$(hostname -I | awk '{print $1}')
echo "[6/6] Done!"
echo
echo "Installer available at:"
echo "👉 http://$IP:$PORT/install.php"
echo


