#!/usr/bin/env bash
# Sub-10s smoke test: RDKit roundtrip, Chemprop CLI, Vina CLI, DiffDock import.
set -euo pipefail

echo "[smoke] python: $(python --version)"

echo "[smoke] RDKit roundtrip …"
python - <<'PY'
from rdkit import Chem
from rdkit.Chem import AllChem
mol = Chem.MolFromSmiles("CC(=O)Oc1ccccc1C(=O)O")  # aspirin
assert mol is not None and mol.GetNumAtoms() == 13
mol_h = Chem.AddHs(mol)
assert AllChem.EmbedMolecule(mol_h, AllChem.ETKDGv3()) == 0
print("  ok")
PY

echo "[smoke] torch + CUDA …"
python -c "import torch; print(f'  torch {torch.__version__}  cuda={torch.cuda.is_available()}')"

echo "[smoke] Chemprop CLI …"
chemprop --help >/dev/null && echo "  ok"

echo "[smoke] AutoDock Vina CLI …"
vina --version >/dev/null && echo "  ok"

echo "[smoke] DiffDock module present …"
test -f /opt/DiffDock/inference.py && echo "  ok"

echo "[smoke] all checks passed."
