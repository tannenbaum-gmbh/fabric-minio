# fabric-minio

This repository is prepared for developing a MinIO on Azure Container Apps solution that can be connected to Microsoft Fabric.

## What is included

- Azure CLI + Bicep tooling in the dev container
- Bicep module alias configuration for AVM usage (`/home/runner/work/fabric-minio/fabric-minio/infra/bicepconfig.json`)
- An AVM-based Bicep deployment for Log Analytics, Azure Container Apps, and a test MinIO instance (`/home/runner/work/fabric-minio/fabric-minio/infra/main.bicep`)
- A Jupyter notebook that creates the resource group, deploys the template, and prints the Fabric endpoint plus MinIO credentials (`/home/runner/work/fabric-minio/fabric-minio/notebooks/01-solution-walkthrough.ipynb`)

## Start in GitHub Codespaces

1. Open this repository in a new Codespace.
2. Wait for the `postCreateCommand` to complete.
3. Open `/home/runner/work/fabric-minio/fabric-minio/notebooks/01-solution-walkthrough.ipynb`.
4. Run the notebook cells in order:
   - validate Azure CLI and Bicep
   - review or override deployment settings
   - create the resource group
   - validate and deploy `/home/runner/work/fabric-minio/fabric-minio/infra/main.bicep`
   - copy the printed `fabricShortcutServiceUrl`, access key ID, and secret access key into Microsoft Fabric

The notebook writes deployment parameters to a temporary file under `/tmp` so the MinIO secret is not echoed in the Azure CLI command line.

## Local dev container use

If using VS Code Dev Containers locally, open the repository and select **Reopen in Container**.
