# Container Recipes

Ready-to-run **Docker / Apptainer / Singularity** recipes for the most-used tools in this catalogue. The goal is simple: spin up a working environment in minutes without wrestling with CUDA versions, conflicting dependencies, or stale conda channels.

## Why containers?

Most deep-learning biomolecular tools were published as research code: they pin specific Python versions, fight over CUDA toolkits, and depend on scientific libraries (RDKit, OpenMM, PyMOL) that don't always coexist on the same machine. Containers fix this by shipping a fully reproducible environment per tool.

This directory provides **two kinds of recipes**:

1. **Per-stack Dockerfiles** — one container per logically grouped task (e.g. *protein design core*, *small-molecule docking*).
2. **Apptainer/Singularity definition files** — drop-in HPC equivalents (no Docker daemon required, root-less, friendly to university clusters).

## Layout

```
containers/
├── README.md                       # this file
├── QUICKSTART.md                   # 60-second copy-paste guide
├── docker-compose.yml              # multi-container orchestration
├── protein-design/
│   ├── Dockerfile                  # RFdiffusion + ProteinMPNN + ColabFold
│   ├── Apptainer.def               # HPC equivalent
│   ├── environment.yml             # the underlying conda env (reusable)
│   └── README.md                   # what's inside, GPU notes, examples
└── small-molecule/
    ├── Dockerfile                  # RDKit + DiffDock + Chemprop + Vina
    ├── Apptainer.def
    ├── environment.yml
    └── README.md
```

## Naming convention

Each image is published as `awesome-biomol/<stack-name>:<tag>` where `<tag>` is `latest` for the rolling build and `YYYY.MM` for stable monthly snapshots.

## Hardware assumptions

- **GPU stacks** (`protein-design`, parts of `small-molecule`) target **CUDA 12.1** on **NVIDIA Ampere or newer** (RTX 30/40 series, A100, H100). On older hardware, drop to `nvidia/cuda:11.8.0-runtime-ubuntu22.04` in the base image and re-pin torch.
- **CPU-only fallbacks** are documented in each stack's README — useful for tests, sanity checks, and laptop work.
- **Memory**: protein-design loads AlphaFold weights (~3 GB) and RFdiffusion weights (~1 GB); plan for 16 GB GPU VRAM minimum, 32 GB host RAM recommended.

## Status

| Stack            | Docker | Apptainer | CI Tested | Notes                                  |
|------------------|:------:|:---------:|:---------:|----------------------------------------|
| protein-design   |   ✅   |    ✅     |    ⏳     | Tested locally on RTX 4090, A100       |
| small-molecule   |   ✅   |    ✅     |    ⏳     | Tested on CPU + RTX 4090               |
| antibody-design  |  TODO  |   TODO    |   TODO    | Will follow once 2.x stack stabilises  |
| rna-design       |  TODO  |   TODO    |   TODO    | Will follow once 5.x stack stabilises  |

CI integration (GitHub Actions building each image on push) is the next milestone — see issue tracker.

## Contributing

PRs adding a new tool to an existing stack are very welcome. New top-level stacks should:

1. Justify a new container (i.e. why not extend an existing one?).
2. Pin every dependency — no `pip install foo` without a version.
3. Include a one-line smoke test in the stack's `README.md` that runs in <30 s.
4. Provide both a `Dockerfile` and an `Apptainer.def` so HPC users aren't second-class citizens.

See `QUICKSTART.md` for the fastest path from clone to a running container.
