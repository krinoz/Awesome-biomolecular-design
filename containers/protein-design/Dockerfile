# syntax=docker/dockerfile:1.6
#
# awesome-biomol/protein-design
#
# A working environment for the canonical de-novo protein binder design loop:
#   1. RFdiffusion       — backbone generation (Section 2.4 of the catalogue)
#   2. ProteinMPNN       — inverse folding (Section 2.5)
#   3. ColabFold/AF2     — in-silico verification (Section 2.2)
#   4. PyMOL + Biopython — analysis & sanity checks
#
# Targets: Linux x86_64, NVIDIA GPU (Ampere+), CUDA 12.1.
#
# Build:
#   docker build -t awesome-biomol/protein-design:latest containers/protein-design/
#
# Run:
#   docker run --rm -it --gpus all -v "$PWD/work:/work" \
#     awesome-biomol/protein-design:latest

FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# ----------------------------------------------------------------------------
# Base system
# ----------------------------------------------------------------------------
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
        pymol \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Miniforge (drop-in replacement for Miniconda; uses conda-forge by default)
# ----------------------------------------------------------------------------
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:${PATH}

RUN curl -fsSL -o /tmp/miniforge.sh \
        "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" \
    && bash /tmp/miniforge.sh -b -p ${CONDA_DIR} \
    && rm /tmp/miniforge.sh \
    && conda clean -afy

# ----------------------------------------------------------------------------
# Project conda env
# ----------------------------------------------------------------------------
WORKDIR /opt/build
COPY environment.yml /opt/build/environment.yml

RUN conda env create -f /opt/build/environment.yml \
    && conda clean -afy

# Make subsequent RUN/CMD use the env by default
SHELL ["/bin/bash", "-lc"]
RUN echo "conda activate protein-design" >> /etc/profile.d/conda-init.sh
ENV PATH=${CONDA_DIR}/envs/protein-design/bin:${PATH}

# ----------------------------------------------------------------------------
# RFdiffusion
# ----------------------------------------------------------------------------
WORKDIR /opt
RUN git clone --depth 1 https://github.com/RosettaCommons/RFdiffusion.git \
    && cd RFdiffusion \
    && pip install --no-deps -e .

# Pre-create the model directory; users mount weights here at runtime.
RUN mkdir -p /opt/RFdiffusion/models

# ----------------------------------------------------------------------------
# ProteinMPNN  (light-weight; no compiled extensions)
# ----------------------------------------------------------------------------
RUN git clone --depth 1 https://github.com/dauparas/ProteinMPNN.git /opt/ProteinMPNN

# ----------------------------------------------------------------------------
# ColabFold (LocalColabFold flavour for offline use)
# ----------------------------------------------------------------------------
RUN pip install "colabfold[alphafold]==1.5.5"

# ----------------------------------------------------------------------------
# Convenience: a /work dir for bind mounts + a smoke-test script
# ----------------------------------------------------------------------------
WORKDIR /work
COPY smoke-test.sh /usr/local/bin/smoke-test
RUN chmod +x /usr/local/bin/smoke-test

CMD ["bash", "-l"]
