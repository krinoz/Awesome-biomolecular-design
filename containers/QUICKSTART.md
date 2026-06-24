# Containers — 60-second Quickstart

Pick the stack that matches your task and follow the three lines under it.

## Protein / peptide binder design

```bash
# Build (or `docker pull` the published image once CI is live)
docker build -t awesome-biomol/protein-design:latest containers/protein-design/

# Run — drops you in a shell with RFdiffusion, ProteinMPNN, ColabFold ready
docker run --rm -it --gpus all \
  -v "$PWD/work:/work" \
  awesome-biomol/protein-design:latest

# Smoke test (inside the container)
python -c "import torch; print('CUDA:', torch.cuda.is_available())"
```

## Small-molecule discovery

```bash
docker build -t awesome-biomol/small-molecule:latest containers/small-molecule/

docker run --rm -it --gpus all \
  -v "$PWD/work:/work" \
  awesome-biomol/small-molecule:latest

# Smoke test
python -c "from rdkit import Chem; print(Chem.MolFromSmiles('CCO').GetNumAtoms())"
```

## HPC / Apptainer

If your cluster doesn't allow Docker:

```bash
# Build the SIF image (one-off, takes ~15 min the first time)
apptainer build protein-design.sif containers/protein-design/Apptainer.def

# Run with GPU passthrough
apptainer exec --nv -B /scratch/$USER:/work protein-design.sif bash
```

## Multi-tool orchestration

For pipelines that need both stacks to talk to each other (e.g. design a protein with RFdiffusion, then dock a small molecule against it):

```bash
docker compose -f containers/docker-compose.yml up -d
docker compose exec protein bash    # design
docker compose exec smallmol bash   # dock
```

The compose file mounts `./work` into both containers under `/work`, so any file written by one is visible to the other.

## Troubleshooting

| Symptom                                                          | Cause                              | Fix                                                |
|------------------------------------------------------------------|------------------------------------|----------------------------------------------------|
| `OCI runtime exec failed: ...nvidia-smi: not found`              | NVIDIA Container Toolkit missing   | `sudo apt install nvidia-container-toolkit`        |
| `RuntimeError: CUDA out of memory`                               | Model too large for your VRAM       | Use the CPU fallback or reduce `--num_designs`     |
| `Permission denied` on bind-mounted files                        | UID mismatch between host & image  | `--user "$(id -u):$(id -g)"`                       |
| Apptainer can't see GPU                                          | `--nv` flag missing                | Add `--nv` to `apptainer exec/run`                 |

For tool-specific errors, see the individual stack `README.md`s.
