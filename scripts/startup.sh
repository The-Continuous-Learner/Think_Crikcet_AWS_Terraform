#!/bin/bash
# EC2 user_data startup script for Think Cricket.
# Rendered by Terraform templatefile() — ${var} tokens are substituted at apply time.
# All output is written to /var/log/startup.log for debugging via SSM Session Manager.
set -euo pipefail
exec > >(tee /var/log/startup.log) 2>&1

echo "=== Think Cricket startup: $(date) ==="

# ── Terraform-substituted values ─────────────────────────────────────────────
JAR_S3_BUCKET="${jar_s3_bucket}"
JAR_S3_KEY="${jar_s3_key}"
AWS_REGION="${aws_region}"
SSM_PREFIX="${ssm_prefix}"
APP_PORT="${app_port}"

# ── System setup ──────────────────────────────────────────────────────────────
echo "Installing Java 17..."
dnf install -y java-17-amazon-corretto-headless

echo "Creating app user and directories..."
useradd -r -s /sbin/nologin think-cricket || true
mkdir -p /opt/think-cricket
chown think-cricket:think-cricket /opt/think-cricket

# ── Pull jar from S3 ─────────────────────────────────────────────────────────
echo "Pulling jar from s3://$JAR_S3_BUCKET/$JAR_S3_KEY ..."
aws s3 cp "s3://$JAR_S3_BUCKET/$JAR_S3_KEY" /opt/think-cricket/app.jar \
  --region "$AWS_REGION"
chown think-cricket:think-cricket /opt/think-cricket/app.jar

# ── Fetch secrets from SSM Parameter Store ───────────────────────────────────
echo "Fetching secrets from SSM ($SSM_PREFIX)..."

ssm_get() {
  aws ssm get-parameter \
    --name "$1" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text \
    --region "$AWS_REGION"
}

DB_URL=$(ssm_get "$SSM_PREFIX/DB_URL")
DB_USERNAME=$(ssm_get "$SSM_PREFIX/DB_USERNAME")
DB_PASSWORD=$(ssm_get "$SSM_PREFIX/DB_PASSWORD")

# Write env file with restricted permissions (root-readable only)
cat > /opt/think-cricket/.env <<EOF
SPRING_DATASOURCE_URL=$DB_URL
SPRING_DATASOURCE_USERNAME=$DB_USERNAME
SPRING_DATASOURCE_PASSWORD=$DB_PASSWORD
SERVER_PORT=$APP_PORT
EOF
chmod 600 /opt/think-cricket/.env
chown think-cricket:think-cricket /opt/think-cricket/.env

# ── CloudWatch log group ──────────────────────────────────────────────────────
aws logs create-log-group \
  --log-group-name "/think-cricket/app" \
  --region "$AWS_REGION" 2>/dev/null || true

# ── systemd service ───────────────────────────────────────────────────────────
echo "Creating systemd service..."
cat > /etc/systemd/system/think-cricket.service <<EOF
[Unit]
Description=Think Cricket Spring Boot App
After=network.target

[Service]
Type=simple
User=think-cricket
WorkingDirectory=/opt/think-cricket
EnvironmentFile=/opt/think-cricket/.env
ExecStart=/usr/bin/java -jar /opt/think-cricket/app.jar
Restart=on-failure
RestartSec=15
StandardOutput=journal
StandardError=journal
SyslogIdentifier=think-cricket

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable think-cricket
systemctl start think-cricket

echo "=== Startup complete: $(date) ==="
echo "App should be available on port $APP_PORT in ~30 seconds"
