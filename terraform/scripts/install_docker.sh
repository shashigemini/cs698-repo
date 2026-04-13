#!/bin/bash
# Install Docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-compose-plugin

# Start Docker
systemctl start docker
systemctl enable docker

# Clone the repository
cd /home/ubuntu
git clone https://github.com/shashigemini/cs698-repo.git
cd cs698-repo

# Create .env file from template (passed via terraform)
cat <<EOF > .env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=spiritual_qa
OPENAI_API_KEY=${OPENAI_API_KEY}
CSRF_SECRET=${CSRF_SECRET}
JWT_PRIVATE_KEY='${JWT_PRIVATE_KEY}'
JWT_PUBLIC_KEY='${JWT_PUBLIC_KEY}'
ENVIRONMENT=production
EOF

# Run the app
docker compose -f docker-compose.prod.yml up -d
