# protein-design — Container

A single image that lets you go from "I want to design a binder against this PDB" to a folded, scored candidate in one shell.

## What's inside

| Tool          | Section in catalogue | Purpose                                            |
|---------------|----------------------|----------------------------------------------------|
| RFdiffusion   | 2.4                  | Diffusion-based backbone generation                |
| ProteinMPNN   | 2.5                  | Sequence design (inverse folding) on the backbone  |
| ColabFold     | 2.2                  | AF2 verification + complex prediction              |
| OpenMM 8      | 1.9                  | Quick MD relaxation / energy minimisation          |
| PDBFixer      | utility              | Cleans crystal structures before design            |
| RDKit         | 1.x                  | Ligand prep when designing enzyme-binders          |
| Biopython     | utility              | I/O, residue arithmetic                            |
| PyMOL         | utility              | CLI rendering & analysis (`pymol -cq script.pml`)  |
| MDAnalysis    | utility              | Trajectory analysis                                |

## Build

```bash
docker build -t awesome-biomol/protein-design:latest containers/protein-design/
```

First build is ~15 minutes (PyTorch + CUDA toolkit pull dominate). Subsequent
builds reuse cached layers.

## Run

```bash
docker run --rm -it --gpus all \
  -v "$PWD/work:/work" \
  -v "$PWD/weights:/opt/RFdiffusion/models" \
  awesome-biomol/protein-design:latest
```

The two bind mounts are intentional:
- `work/` is your scratch directory; everything in `/work` inside the container
  is just your local `./work`.
- `weights/` is where you put RFdiffusion's `.pt` checkpoint files. Download
  them once (~1 GB) following the upstream repo's instructions, and reuse them
  across every container you spin up.

## Smoke test

```bash
docker run --rm --gpus all awesome-biomol/protein-design:latest smoke-test
```

Expected output ends with `[smoke] all checks passed.`

## End-to-end example: design 8 binders against PDB 1QYS

```bash
# inside the container
cd /work

# 1. Generate 8 backbones with RFdiffusion (motif scaffolding from chain A 30-50)
python /opt/RFdiffusion/scripts/run_inference.py \
    inference.output_prefix=designs/binder \
    inference.input_pdb=1qys.pdb \
    contigmap.contigs="[A30-50/0 70-100]" \
    inference.num_designs=8

# 2. Sequence design over the new backbones
python /opt/ProteinMPNN/protein_mpnn_run.py \
    --pdb_path designs/ \
    --out_folder seqs/ \
    --num_seq_per_target 4 \
    --sampling_temp 0.1

# 3. Verify with ColabFold (single-sequence, fast)
colabfold_batch seqs/seqs.fasta verified/ \
    --msa-mode single_sequence --num-models 1
```

## CPU fallback

If you don't have a CUDA-capable GPU, replace the base image with
`ubuntu:22.04` and pin `pytorch::pytorch=2.3.*` without the `pytorch-cuda`
package. Generation drops from minutes to ~1 hour for the same 8 designs;
useful for sanity checks but not realistic batch work.

## Versioning

| Tag      | RFdiffusion | ProteinMPNN | ColabFold | PyTorch | CUDA |
|----------|-------------|-------------|-----------|---------|------|
| `latest` | main HEAD   | main HEAD   | 1.5.5     | 2.3.x   | 12.1 |
| `2026.05`| pinned      | pinned      | 1.5.5     | 2.3.1   | 12.1 |

Pinned tags are cut once a month after the smoke-tests pass; use `latest`
for the rolling build and a dated tag in scripts you want to be reproducible.
