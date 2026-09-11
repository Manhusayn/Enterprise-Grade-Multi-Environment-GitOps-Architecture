#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gitops-lab}"

if command -v kind >/dev/null 2>&1; then
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "kind is not installed."
  exit 1
fi
