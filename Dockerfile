# Use official Argo CD CLI image
ARG ARGOCD_VERSION=v3.0.12
FROM quay.io/argoproj/argocd:${ARGOCD_VERSION}

# Switch to root to allow writing to mounted volumes
USER root

# Copy entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
