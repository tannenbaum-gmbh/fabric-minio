#!/usr/bin/env bash
set -euo pipefail

python -m pip install --upgrade pip
python -m pip install -r .devcontainer/requirements.txt
python -m ipykernel install --user --name fabric-minio --display-name "Python (fabric-minio)"

az bicep install
az bicep version
