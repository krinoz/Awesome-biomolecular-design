# Chapter 3 — Designing Protein & Peptide Binders

You want a **mini-protein** (60–120 residues), a **scaffold protein**, or a **peptide** (5–40 residues, possibly cyclic) that binds your target. This chapter walks the modern RFdiffusion + ProteinMPNN + AlphaFold loop, with detours for peptide- and macrocycle-specific tooling.

## 3.1 Decision tree

```
What's the binder length you need?
│
├─ 5–30 residues         ──► Peptide / macrocycle (§3.6)
│                              – PepFlow, PepMLM, RFpeptides, CycleDesigner
│
├─ 50–120 residues       ──► Mini-protein binder (§3.3 — main route)
│                              – RFdiffusion → ProteinMPNN → AF2 verify
│
├─ 120–300 residues      ──► Scaffold / domain (§3.5)
│                              – Chroma, Genie2, RFdiffusion
│
└─ >300 residues         ──► You probably don't need de-novo design.
                              Look for a natural binder via Foldseek (§0.3),
                              then optimize with EvoProtGrad (§2.6).
```

## 3.2 Target prep — protein-binder specifics

In addition to the Chapter 1 prep:

- **Define the *hotspot* residues.** RFdiffusion accepts a `hotspot_res` argument that strongly biases the new backbone to interact with those residues. Typically 3–6 surface-exposed residues at the desired epitope.
- **Mask any cysteines you don't want disulphide-bonded.** ProteinMPNN happily builds Cys-Cys bridges that mess up the design.
- **Consider the conformational state.** If your target is a kinase, you almost certainly want either DFG-in or DFG-out exclusively. Use **AlphaFlow** (§2.2b) to get an ensemble, then design against the conformer you care about.

## 3.3 The canonical mini-protein binder loop

This is the workhorse. Run it first; deviate only if it fails.

```bash
# Inside the protein-design container, /work mounted

# 0. One-time: download RFdiffusion checkpoints into /opt/RFdiffusion/models

# 1. Generate 200 backbones
python /opt/RFdiffusion/scripts/run_inference.py \
    inference.output_prefix=designs/binder \
    inference.input_pdb=target_clean.pdb \
    'contigmap.contigs=[A20-180/0 60-100]' \
    'ppi.hotspot_res=[A57,A60,A114]' \
    inference.num_designs=200 \
    denoiser.noise_scale_ca=0 \
    denoiser.noise_scale_frame=0
# (zero noise scales = "partial diffusion" mode for tighter binders)

# 2. Sequence design — 4 sequences per backbone
python /opt/ProteinMPNN/protein_mpnn_run.py \
    --pdb_path designs/ \
    --out_folder seqs/ \
    --num_seq_per_target 4 \
    --sampling_temp 0.1 \
    --use_soluble_model

# 3. AF2 verification
colabfold_batch seqs/seqs.fasta verified/ \
    --msa-mode single_sequence --num-models 1
```

Look for designs that satisfy **all three** of these criteria:

1. **AF2 pLDDT > 80** for the binder.
2. **AF2 PAE < 10** at the binder–target interface.
3. **AF2-predicted binder structure RMSD to RFdiffusion backbone < 2 Å.**

A typical campaign yields 10–30% of designs passing all three. Among the passing designs, in published Baker-lab campaigns ~5–25% bind at sub-µM affinity in the wet lab — the actual rate depends heavily on the target.

## 3.4 Re-scoring & developability for proteins

| Score                                 | What it measures                | Good range                   |
|---------------------------------------|---------------------------------|------------------------------|
| AF2 pLDDT (binder)                    | Folding confidence              | > 80                         |
| AF2 ipTM / PAE @ interface            | Interaction confidence          | ipTM > 0.7, PAE < 10 Å       |
| ESM2 perplexity                       | Naturalness                     | < 7                          |
| **PPIformer / GearBind** (§2.8)       | Predicted ΔΔG of binder mutants | Use to scan for stability    |
| **NetSurfP-3 / SAP**                  | Aggregation propensity          | SAP < 30                     |
| Net charge at pH 7                    | Solubility                      | Avoid |Z| > 10                |
| Predicted melting temp (TEMPRO §3.7)  | Thermal stability               | Tm > 60 °C                   |

A binder that scores well on AF2 but has a SAP score of 80 will end up in the inclusion-body pellet. Always check.

## 3.5 Larger scaffolds & enzymes

For >120-residue designs use **RFdiffusion All-Atom** (RFAA) or **Chroma** with a structural guideline. Inverse folding switches to **LigandMPNN** (§2.5) when you have a bound ligand or cofactor.

## 3.6 Peptide & macrocycle binders

Peptides have to fight their own conformational entropy, so the toolset is different.

| Sub-task                          | Tool                                       |
|-----------------------------------|--------------------------------------------|
| Linear peptide binder (5–30 aa)   | **PepMLM** or **PepFlow** (§2.4 / agentic) |
| Macrocycle / cyclic peptide       | **RFpeptides**, **CycleDesigner**          |
| Affinity maturation               | **EvoProtGrad** (§2.6)                     |
| MD relaxation                     | OpenMM 8 in the container, AMBER ff14SB    |

A working pattern:

```bash
# 1. Generate 500 cyclic peptides (length 12–18) against epitope
python /opt/RFpeptides/sample.py \
    --target target_clean.pdb \
    --hotspots A57,A60,A114 \
    --length 14 --num_samples 500 \
    --cyclize --output cyclic/

# 2. Sequence-design with ProteinMPNN (allow non-standard residues if you can synthesise them)
python /opt/ProteinMPNN/protein_mpnn_run.py --pdb_path cyclic/ ...

# 3. Re-fold each one with PepFlow / AF3 (peptides are tricky for AF2)
# 4. MD-relax the surviving 50, score the average per-residue interaction energy
```

## 3.7 Worked example: PD-L1 mini-binder

A reproducible end-to-end run against PDB **5O45** (PD-L1 ECD) — one of the canonical RFdiffusion benchmarks.

```bash
# Hotspots from published wet-lab characterisation: I54, Y56, E58
python /opt/RFdiffusion/scripts/run_inference.py \
    inference.output_prefix=pdl1_binders/binder \
    inference.input_pdb=5o45_chainA.pdb \
    'contigmap.contigs=[A18-129/0 65-95]' \
    'ppi.hotspot_res=[A54,A56,A58]' \
    inference.num_designs=400 \
    denoiser.noise_scale_ca=0 denoiser.noise_scale_frame=0

python /opt/ProteinMPNN/protein_mpnn_run.py \
    --pdb_path pdl1_binders/ --out_folder pdl1_seqs/ \
    --num_seq_per_target 8 --use_soluble_model --sampling_temp 0.1

colabfold_batch pdl1_seqs/seqs.fasta pdl1_verified/ --msa-mode single_sequence --num-models 1

python filter_designs.py pdl1_verified/ \
    --min-plddt 80 --max-pae 10 --max-rmsd 2.0 \
    > shortlist.csv
```

Wall-clock on a single A100: ~14 hours. Expected: 20–80 designs in `shortlist.csv`; in published Baker-lab campaigns against PD-L1, in vitro hit rates among such filtered designs ran ~10–30%.

## 3.8 What the agentic stack changes

**ProtAgents** (§6.3) wraps RFdiffusion + ProteinMPNN + ColabFold + ProteinForceGPT into a multi-agent driver that picks scaffold lengths and hotspot subsets autonomously. Useful when you don't yet have an opinion on the design parameters; less useful once you've run two campaigns and know what works.

**Robin** (§6.6) is the right tool when you need to discover a *target* and then a *binder against it* in one loop — it runs literature search, hypothesis generation, candidate design, and analysis end-to-end. Not appropriate when you already have your target nailed down.
