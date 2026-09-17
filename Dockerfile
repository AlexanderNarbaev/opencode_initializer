# syntax=docker/dockerfile:1

# =============================================================================
# opencode_initializer — development/analysis/design container
#
# Multi-stage build: toolchains and Node.js globals are assembled in the
# `builder` stage, then copied into a slim runtime image running as a
# non-root `opencode` user.
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build dependencies
# -----------------------------------------------------------------------------
FROM node:20-bookworm-slim AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies needed to fetch/build toolchains
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    openjdk-17-jre-headless \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.26
RUN curl -fsSL https://go.dev/dl/go1.26.5.linux-amd64.tar.gz \
    | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Rust (stable toolchain)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain stable
ENV CARGO_HOME="/root/.cargo" \
    RUSTUP_HOME="/root/.rustup" \
    PATH="/root/.cargo/bin:${PATH}"

# Install .NET 10
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && bash /tmp/dotnet-install.sh --channel 10.0 --install-dir /root/.dotnet \
    && rm /tmp/dotnet-install.sh
ENV DOTNET_ROOT="/root/.dotnet" \
    PATH="/root/.dotnet:${PATH}"

# Install Node.js tools
RUN npm install -g opencode-ai @colbymchenry/codegraph

# -----------------------------------------------------------------------------
# Stage 2: Final image
# -----------------------------------------------------------------------------
FROM node:20-bookworm-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy dependencies from builder (relocated out of /root so the non-root
# `opencode` user can read them)
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /root/.cargo /usr/local/cargo
COPY --from=builder /root/.rustup /usr/local/rustup
COPY --from=builder /root/.dotnet /usr/local/dotnet

# Copy Node.js global modules and recreate the two global binaries
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/opencode-ai/bin/opencode.exe /usr/local/bin/opencode \
    && ln -s /usr/local/lib/node_modules/@colbymchenry/codegraph/npm-shim.js /usr/local/bin/codegraph

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    libicu72 \
    libssl3 \
    openjdk-17-jre-headless \
    python3 \
    python3-pip \
    python3-venv \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PATH="/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/dotnet:${PATH}" \
    GOROOT="/usr/local/go" \
    GOPATH="/home/opencode/go" \
    GOCACHE="/home/opencode/.cache/go-build" \
    CARGO_HOME="/usr/local/cargo" \
    RUSTUP_HOME="/usr/local/rustup" \
    DOTNET_ROOT="/usr/local/dotnet" \
    DOTNET_CLI_HOME="/home/opencode/.dotnet" \
    DOTNET_NOLOGO=1 \
    NODE_TLS_REJECT_UNAUTHORIZED=0 \
    OPENCODE_STRICT_VALIDATION=false

# Create non-root user and hand over ownership of the writable toolchains
RUN useradd -m -s /bin/bash opencode \
    && chown -R opencode:opencode /usr/local/cargo /usr/local/rustup

USER opencode

# Create workspace
WORKDIR /workspace

# Health check for the web server
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -fsS http://localhost:4096/health || exit 1

# Expose port
EXPOSE 4096

# Entrypoint
ENTRYPOINT ["opencode", "web", "--hostname", "0.0.0.0", "--port", "4096"]
