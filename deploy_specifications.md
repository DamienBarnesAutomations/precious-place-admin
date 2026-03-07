# Deployment Specifications: GHCR Image-Based Workflow

This document details the transition from a git-based deployment (pulling code on the server) to an image-based deployment using GitHub Container Registry (GHCR).

## 1. Architectural Shift

*   **Current**: GHA connects to server -> Server clones/pulls code -> Server builds images locally using `docker compose up --build`.
*   **New**: GHA builds and pushes images to GHCR -> GHA connects to server -> Server pulls pre-built images from GHCR -> Server restarts containers using `docker compose up`.

## 2. CI Phase: Image Building (GitHub Actions)

The GHA runner will be responsible for building and tagging images for all custom services.

### 2.1 Services to Build
1.  **`pos_frontend`**: Built from `./pos-frontend/Dockerfile`.
2.  **`ledger_frontend`**: Built from `./ledger-frontend/Dockerfile`.
3.  **`custom_cake_frontend`**: Built from `./custom-cake-order-manager/custom_cake_frontend/Dockerfile`.
4.  **`python_app`**: Built from `./custom-cake-order-manager/python_app/Dockerfile`.
5.  **`n8n_custom`**: A new custom image based on `n8nio/n8n:latest` that includes the `n8n-import.sh` script and workflow JSONs, removing the need to mount them as volumes on the server.

### 2.2 Tagging Strategy
*   Images will be tagged with both the branch name (`staging`) and the specific commit SHA for rollback capabilities.
*   Registry: `ghcr.io/damienbarnesautomations/precious-place-admin/<service-name>:staging`.

### 2.3 Build Arguments
Frontend images require `VITE_*` variables at build time. These will be extracted from the `ENV_JSON` secret during the build step.

## 3. Configuration Management

Since code will no longer be checked out on the server, we must explicitly transfer "Infrastructure as Code" files and persistent volume structures.

### 3.1 Files to Transfer via SCP
The following files are required on the server to orchestrate the containers:
*   `docker-compose.yml` (Base infrastructure).
*   `docker-compose.override.yml` (Integrated sub-module logic).
*   `.env` (Generated from secrets).
*   `letsencrypt/acme.json` (SSL state).

### 3.2 Server-Side Directory Structure
The deployment script will ensure the following persistent volumes exist:
*   `/app/postgres/db-data` (Database persistence).
*   `/app/n8n/flows2` (n8n internal data).
*   `/app/public/images/` (Static assets like product and cake images).

## 4. CD Phase: Orchestration (Server)

### 4.1 Authentication
The server will log in to GHCR using a GitHub Personal Access Token (PAT) or the `GITHUB_TOKEN` provided by the workflow to pull private images.

### 4.2 Deployment Execution
The deployment step will run:
```bash
docker compose pull # Pull latest images from GHCR
docker compose up -d --remove-orphans
docker image prune -f # Clean up old images to save disk space
```

## 5. Implementation Steps

### 5.1 Dockerfile Updates
*   Create a custom Dockerfile for `n8n` to bake scripts into the image.
*   Update `image_server` (Nginx) to point to the correct static asset path if needed.

### 5.2 Workflow Modification (`deploy_staging.yml`)
*   **Add `permissions`**: Ensure the workflow has `packages: write` access.
*   **Add Build Job**: A new job `build-and-push` that runs before `deploy`.
*   **Update Deploy Job**:
    *   Remove `Sync Repository` step (no more `git clone`).
    *   Update `scp` to only transfer configuration files.
    *   Update `docker compose` command to pull images instead of building.

### 5.3 Docker Compose Update
*   Modify `docker-compose.yml` and `docker-compose.override.yml` to use `image: ghcr.io/...` instead of `build: .`.
*   *Note*: For local development, we will keep a `docker-compose.dev.yml` that still uses `build:` to allow for rapid iteration.
