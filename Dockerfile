# Use official Argo CD CLI image
ARG ARGOCD_VERSION=v3.0.12
FROM quay.io/argoproj/argocd:${ARGOCD_VERSION}

# Switch to root to allow writing to mounted volumes
USER root

# Install bash, git, curl (for your entrypoint and git diff)
RUN apt-get update \
 && apt-get install -y --no-install-recommends bash git curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# --- yq install (arch-aware) ---
ARG YQ_VERSION=v4.44.3
# Provided by BuildKit during build (docker buildx); defaults are fine if absent
ARG TARGETOS
ARG TARGETARCH
# Map TARGETARCH to yq's asset suffix
RUN set -eux; \
  arch=""; \
  case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
    amd64|x86_64) arch="amd64" ;; \
    arm64|aarch64) arch="arm64" ;; \
    armhf|arm) arch="arm" ;; \
    *) echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
  esac; \
  os="${TARGETOS:-linux}"; \
  url="https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${os}_${arch}"; \
  echo "Downloading ${url}"; \
  curl -fsSL "$url" -o /usr/local/bin/yq; \
  chmod +x /usr/local/bin/yq; \
  /usr/local/bin/yq --version

# Copy entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
