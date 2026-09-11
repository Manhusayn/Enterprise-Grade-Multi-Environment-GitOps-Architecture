#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required"; exit 1; }

echo "==> Running application tests"
(
  cd "$ROOT/app"
  python3 -m unittest discover -s tests -p "test_*.py"
)

echo "==> Validating Kustomize overlays"
for env in dev stage prod; do
  echo "    - $env"
  kubectl kustomize "$ROOT/gitops/environments/$env" >/tmp/gitops-"$env".yaml
  test -s /tmp/gitops-"$env".yaml
done

echo "==> Validating YAML syntax"
python3 - "$ROOT" <<'PY'
import sys
from pathlib import Path
import yaml

root = Path(sys.argv[1])
for path in root.rglob("*.yaml"):
    with path.open() as f:
        list(yaml.safe_load_all(f))
    print(f"OK {path.relative_to(root)}")
PY

echo "SUCCESS: project validation completed."
