FROM n8nio/n8n:latest

USER root

# Install dos2unix using apt-get (Debian-based image)
RUN apt-get update && apt-get install -y dos2unix && rm -rf /var/lib/apt/lists/*

# Create directories for workflows
RUN mkdir -p /home/node/.n8n-files/workflows /home/node/.n8n-files/cake-workflows

# Copy workflows and scripts from root
COPY n8n/n8n-workflows /home/node/.n8n-files/workflows

# Copy workflows from sub-module
COPY custom-cake-order-manager/n8n/n8n-workflows /home/node/.n8n-files/cake-workflows

# Fix line endings and permissions for the script
RUN dos2unix /home/node/.n8n-files/workflows/n8n-init/n8n-import.sh && \
    chmod +x /home/node/.n8n-files/workflows/n8n-init/n8n-import.sh

# Ensure the node user owns these files
RUN chown -R node:node /home/node/.n8n-files

USER node

# Set the entrypoint to our import script
ENTRYPOINT ["/bin/sh", "/home/node/.n8n-files/workflows/n8n-init/n8n-import.sh"]
