# syntax=docker/dockerfile:1.6
#
# awesome-biomol/small-molecule
#
# A working environment for the canonical small-molecule discovery loop:
#   1. RDKit              — featurisation, descriptors, conformers (Section 1.x)
#   2. Chemprop           — D-MPNN property/ADMET prediction (Section 1.6)
#   3. AutoDock Vina      — classical docking (Section 1.8)
#   4. DiffDock           — generative blind docking (Section 1.8)
#   5. OpenBabel + Meeko  — ligand prep glue
#   6. PyMOL              — visualisation
#
# Build:
#   docker build -t awesome-biomol/small-molecule:latest containers/small-molecule/
#
# Run:
#   docker run --rm -it --gpus all -v "$PWD/work:/work" \
#     awesome-biomol/small-molecule:latest

FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        wget \
        unzip \
        bzip2 \
        cmake \
        ninja-build \
        gfortran \
        libopenblas-dev \
        libgomp1 \
        libxrender1 \
        libxext6 \
        libsm6 \
        autodock-vina \
        pymol \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Miniforge + project conda env
# ----------------------------------------------------------------------------
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:${PATH}

RUN curl -fsSL -o /tmp/miniforge.sh \
        "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" \
    && bash /tmp/miniforge.sh -b -p ${CONDA_DIR} \
    && rm /tmp/miniforge.sh \
    && conda clean -afy

WORKDIR /opt/build
COPY environment.yml /opt/build/environment.yml

RUN conda env create -f /opt/build/environment.yml \
    && conda clean -afy

SHELL ["/bin/bash", "-lc"]
RUN echo "conda activate small-molecule" >> /etc/profile.d/conda-init.sh
ENV PATH=${CONDA_DIR}/envs/small-molecule/bin:${PATH}

# ----------------------------------------------------------------------------
# DiffDock (generative blind docking)
# ----------------------------------------------------------------------------
WORKDIR /opt
RUN git clone --depth 1 https://github.com/gcorso/DiffDock.git \
    && cd DiffDock \
    && pip install --no-deps -r requirements.txt

# Pre-create the model dir; users mount the published weights here.
RUN mkdir -p /opt/DiffDock/workdir

# ----------------------------------------------------------------------------
# Meeko (ligand prep for Vina/AutoDock)
# ----------------------------------------------------------------------------
RUN pip install meeko==0.6.*

# ----------------------------------------------------------------------------
# Smoke test + work dir
# ----------------------------------------------------------------------------
WORKDIR /work
COPY smoke-test.sh /usr/local/bin/smoke-test
RUN chmod +x /usr/local/bin/smoke-test

CMD ["bash", "-l"]
