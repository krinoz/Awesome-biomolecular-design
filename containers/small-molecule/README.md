# small-molecule — Container

A single image covering the most common small-molecule discovery moves: featurise → predict properties → dock → score.

## What's inside

| Tool             | Section in catalogue | Purpose                                          |
|------------------|----------------------|--------------------------------------------------|
| RDKit            | 1.1                  | Cheminformatics — descriptors, FPs, conformers   |
| Chemprop 2.0     | 1.6                  | D-MPNN property/ADMET prediction                 |
| AutoDock Vina    | 1.8                  | Classical, fast docking                          |
| DiffDock         | 1.8                  | Generative blind docking                         |
| Meeko            | utility              | Ligand → PDBQT prep for Vina                     |
| OpenBabel        | utility              | File-format conversion glue                      |
| Mordred          | 1.6                  | 1800+ descriptors for QSAR baselines             |
| OpenMM 8         | 1.9                  | Quick MD relaxation / FEP setup                  |
| PyMOL            | utility              | CLI rendering & visualisation                    |

## Build

```bash
docker build -t awesome-biomol/small-molecule:latest containers/small-molecule/
```

~12 minutes the first time.

## Run

```bash
docker run --rm -it --gpus all \
  -v "$PWD/work:/work" \
  -v "$PWD/diffdock-weights:/opt/DiffDock/workdir" \
  awesome-biomol/small-molecule:latest
```

The `diffdock-weights/` mount is where the published DiffDock checkpoints
live; download once and reuse across container runs.

## Smoke test

```bash
docker run --rm --gpus all awesome-biomol/small-molecule:latest smoke-test
```

## End-to-end example: virtual screening 1 000 ChEMBL hits against a target

```bash
# inside the container, /work mounted from your host
cd /work

# 1. Featurise + predict pIC50 with Chemprop (assumes you trained a model upstream)
chemprop predict \
    --test-path candidates.csv \
    --smiles-columns SMILES \
    --model-path models/pic50.pt \
    --preds-path candidates_predicted.csv

# 2. Take the top 100 by predicted potency
python - <<'PY'
import pandas as pd
df = pd.read_csv("candidates_predicted.csv")
top = df.nlargest(100, "pIC50_pred")
top.to_csv("top100.smi", columns=["SMILES"], index=False, header=False)
PY

# 3. Prepare ligands for Vina (Meeko) and dock against target.pdbqt
mkdir -p ligands docks
while read SMI; do
    name=$(echo "$SMI" | md5sum | cut -c1-8)
    mk_prepare_ligand.py -i "$SMI" -o "ligands/${name}.pdbqt"
    vina --receptor target.pdbqt --ligand "ligands/${name}.pdbqt" \
         --center_x 12 --center_y 8 --center_z -3 \
         --size_x 22 --size_y 22 --size_z 22 \
         --out "docks/${name}_out.pdbqt" --log "docks/${name}.log"
done < top100.smi

# 4. (optional) Re-rank the best 20 with DiffDock for higher-quality poses
python /opt/DiffDock/inference.py \
    --protein_path target.pdb \
    --ligand $(head -20 best20.smi | xargs) \
    --out_dir docks_diffdock/
```

## CPU fallback

DiffDock's geometric DL stack (`torch_geometric`, `e3nn`) is slow on CPU but
not unusable for sub-50 ligands. Vina is CPU-only by default and is fast.
Chemprop's CPU path works fine for inference; training is GPU-recommended.

## Versioning

| Tag      | RDKit  | Chemprop | DiffDock  | Vina  | PyTorch | CUDA |
|----------|--------|----------|-----------|-------|---------|------|
| `latest` | 2024.03| 2.0.4    | main HEAD | 1.2.5 | 2.3.x   | 12.1 |
| `2026.05`| pinned | 2.0.4    | pinned    | 1.2.5 | 2.3.1   | 12.1 |
