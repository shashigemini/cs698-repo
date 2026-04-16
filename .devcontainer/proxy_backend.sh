#!/bin/bash

# This script bridges the port 8000 from the devcontainer directly into 
# the sibling docker-compose backend container. 
# It resolves the issue of Flutter Web (running on the host browser) 
# hitting the VS Code port forwarder but failing because the devcontainer 
# has nothing listening on port 8000.

HOST_PORT=8000
TARGET_PORT=8000
APP_HOST="host.docker.internal"

# Check if socat is already running on this port and kill it
EXISTING_PID=$(lsof -t -i:$HOST_PORT)
if [ ! -z "$EXISTING_PID" ]; then
    echo "Killing existing process on port $HOST_PORT (PID: $EXISTING_PID)"
    kill -9 $EXISTING_PID
fi

echo "🚀 Starting socat proxy: localhost:$HOST_PORT -> $APP_HOST:$TARGET_PORT"
nohup socat TCP-LISTEN:$HOST_PORT,fork,reuseaddr TCP:$APP_HOST:$TARGET_PORT > /tmp/socat_proxy.log 2>&1 &
echo "✅ Proxy running in background."

