# Zotero ReScript Templater - Development Container
# Provides a complete development environment with all dependencies

# Base image with recent Ubuntu LTS
FROM ubuntu:22.04

LABEL maintainer="Zotero ReScript Templater Contributors"
LABEL description="Development environment for Zotero plugin scaffolding"
LABEL version="0.1.0"

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Basic utilities
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    gnupg \
    ca-certificates \
    # Build tools
    build-essential \
    # Python for JSON processing
    python3 \
    python3-pip \
    jq \
    # XXHash for integrity verification
    xxhash \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/*

# Install Racket
ARG RACKET_VERSION=8.12
RUN wget -O racket-installer.sh \
    "https://mirror.racket-lang.org/installers/${RACKET_VERSION}/racket-${RACKET_VERSION}-x86_64-linux-cs.sh" && \
    chmod +x racket-installer.sh && \
    ./racket-installer.sh --unix-style --dest /usr/local && \
    rm racket-installer.sh

# Install Node.js LTS (for templates that need it)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g \
    typescript \
    rescript \
    eslint

# Install PowerShell modules
RUN pwsh -Command "Install-Module -Name Pester -Force -Scope AllUsers -AcceptLicense"
RUN pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope AllUsers -AcceptLicense"

# Create workspace directory
WORKDIR /workspace

# Copy project files
COPY . /workspace/

# Set up git config for container
RUN git config --global user.name "Container User" && \
    git config --global user.email "container@example.com" && \
    git config --global init.defaultBranch main

# Create a non-root user for development
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    # Add sudo support
    apt-get update && \
    apt-get install -y sudo && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER $USERNAME

# Set environment variables
ENV PATH="/home/$USERNAME/.local/bin:${PATH}"
ENV SHELL=/bin/bash

# Install additional user-level tools
RUN mkdir -p /home/$USERNAME/.local/bin

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD pwsh -Command "exit 0" && racket -e "(exit 0)"

# Default command
CMD ["/bin/bash"]

# Container usage notes
# ====================
#
# Build the container:
#   podman build -t zotero-templater -f Containerfile .
#   OR
#   docker build -t zotero-templater -f Containerfile .
#
# Run interactively:
#   podman run -it --rm -v $(pwd):/workspace zotero-templater
#
# Run tests:
#   podman run --rm -v $(pwd):/workspace zotero-templater pwsh -Command "Invoke-Pester tests/*.Tests.ps1"
#   podman run --rm -v $(pwd):/workspace zotero-templater racket tests/racket-tests.rkt
#
# Scaffold a plugin:
#   podman run --rm -v $(pwd):/workspace zotero-templater \
#     pwsh ./init-zotero-rscript-plugin.ps1 -ProjectName MyPlugin -AuthorName "Test" -TemplateType student
