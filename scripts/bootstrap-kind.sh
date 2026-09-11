#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gitops-lab}"
IMAGE="${IMAGE:-gitops-demo:1.0.0}"

command -v kind >/dev/null 2>&1 || { echo "ERROR: kind is required."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "ERROR: kubectl is required."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is required."; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' already exists."
else
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT/kind-config.yaml"
fi

echo "==> Building local application image: $IMAGE"
docker build -t "$IMAGE" "$ROOT/app"

echo "==> Loading image into Kind"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

echo "==> Creating environment namespaces"
for ns in dev stage prod; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

kubectl cluster-info --context "kind-$CLUSTER_NAME"
echo "Kind cluster '$CLUSTER_NAME' is ready."
echo "Local image '$IMAGE' is loaded into every Kind node."
