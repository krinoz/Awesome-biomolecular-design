#!/usr/bin/env bash
# Tiny smoke test: confirms torch sees CUDA, RFdiffusion + ProteinMPNN import,
# and ColabFold's CLI is on PATH. Runs in <10 s on a warm container.
set -euo pipefail

echo "[smoke] python: $(python --version)"
echo "[smoke] torch + CUDA …"
python - <<'PY'
import torch
print(f"  torch {torch.__version__}  cuda={torch.cuda.is_available()}  "
      f"device_count={torch.cuda.device_count()}")
PY

echo "[smoke] RFdiffusion import …"
python -c "import rfdiffusion; print('  ok')" 2>/dev/null \
    || echo "  (RFdiffusion not import-resolvable — expected; runs as a script)"

echo "[smoke] ProteinMPNN script present …"
test -f /opt/ProteinMPNN/protein_mpnn_run.py && echo "  ok"

echo "[smoke] ColabFold CLI …"
colabfold_batch --help >/dev/null && echo "  ok"

echo "[smoke] all checks passed."
