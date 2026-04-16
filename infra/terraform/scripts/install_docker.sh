#!/bin/bash
set -e

apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-compose-plugin

systemctl start docker
systemctl enable docker

cd /home/ubuntu
git clone ${REPO_CLONE_URL} cs698-repo
cd cs698-repo/apps/backend

cat <<EOF_ENV > .env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=spiritual_qa
OPENAI_API_KEY=${OPENAI_API_KEY}
CSRF_SECRET=${CSRF_SECRET}
JWT_PRIVATE_KEY='${JWT_PRIVATE_KEY}'
JWT_PUBLIC_KEY='${JWT_PUBLIC_KEY}'
ENVIRONMENT=production
EOF_ENV

cd /home/ubuntu/cs698-repo
docker compose -f infra/production/docker-compose.prod.yml up -d --build
