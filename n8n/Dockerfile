FROM n8nio/n8n:latest

USER root

# Create directories for workflows
RUN mkdir -p /home/node/.n8n-files/workflows /home/node/.n8n-files/cake-workflows

# Copy workflows and scripts from root (Relative to project root context)
COPY n8n/n8n-workflows /home/node/.n8n-files/workflows

# Copy workflows from sub-module (Relative to project root context)
COPY custom-cake-order-manager/n8n/n8n-workflows /home/node/.n8n-files/cake-workflows

# Ensure the node user owns these files
RUN chown -R node:node /home/node/.n8n-files

USER node

# Set the entrypoint to our import script
ENTRYPOINT ["/bin/sh", "/home/node/.n8n-files/workflows/n8n-init/n8n-import.sh"]
