#!/bin/bash
set -euo pipefail

# Add 1GB Swap file
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
fi

apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-compose-plugin

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

REPO_DIR="/home/ubuntu/cs698-repo"

if [ -d "$${REPO_DIR}/.git" ]; then
  git -C "$${REPO_DIR}" fetch --all --prune
  git -C "$${REPO_DIR}" reset --hard origin/main
else
  rm -rf "$${REPO_DIR}"
  git clone "${REPO_CLONE_URL}" "$${REPO_DIR}"
fi

chown -R ubuntu:ubuntu "$${REPO_DIR}"
cd "$${REPO_DIR}/apps/backend"

cat <<EOF_ENV > .env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=spiritual_qa
OPENAI_API_KEY=${OPENAI_API_KEY}
CSRF_SECRET=${CSRF_SECRET}
JWT_PRIVATE_KEY='${JWT_PRIVATE_KEY}'
JWT_PUBLIC_KEY='${JWT_PUBLIC_KEY}'
ENVIRONMENT=production
CORS_ORIGINS='["https://main.d3h75lrebnktpp.amplifyapp.com"]'
EOF_ENV

cd "$${REPO_DIR}"
docker compose -f infra/production/docker-compose.prod.yml up -d --build
