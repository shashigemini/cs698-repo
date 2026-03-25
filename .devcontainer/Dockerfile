FROM mcr.microsoft.com/devcontainers/python:1-3.11-bookworm

# Fix Yarn GPG error by removing the problematic repository list
RUN rm -f /etc/apt/sources.list.d/yarn.list

# Install system dependencies for Flutter Linux, Python extensions, and Host terminal access
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
    # Build tools
    bash curl git xz-utils libglu1-mesa mesa-utils \
    # Flutter Linux dependencies
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev \
    libblkid-dev libsecret-1-dev libjsoncpp-dev \
    # Virtual framebuffer for headless GUI testing
    xvfb \
    # SSH Client / Networking for host terminal access
    openssh-client socat \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN mkdir -p /opt/flutter && \
    curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.41.0-stable.tar.xz | tar -C /opt/flutter -xJ --strip-components=1

# Set permissions for vscode user
RUN chown -R vscode:vscode /opt/flutter

# Set PUB_CACHE and add Flutter and PUB_CACHE bin to PATH
ENV PUB_CACHE="/usr/local/pub-cache"
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PUB_CACHE}/bin:${PATH}"
RUN mkdir -p ${PUB_CACHE} && chown -R vscode:vscode ${PUB_CACHE}

# Pre-install poetry and uv to speed up container startup and improve reliability
USER vscode
RUN pipx install poetry && pipx install uv
# Global poetry config for in-project virtualenvs (matches devcontainer setting)
RUN poetry config virtualenvs.in-project true

# Install Marionette MCP tools
RUN dart pub global activate marionette_mcp && \
    dart pub global activate marionette_cli

# Install MCP tools and additional python CLI utilities
RUN pipx install codegraphcontext && \
    pipx inject codegraphcontext kuzu && \
    pipx install vulture

