# Chapter 5 — Tool-Selection Decision Matrix

Quick reference for "**I just need a tool — what do I pick?**" questions. Everything here is opinionated; the catalogue (`../README.md`) is the comprehensive reference.

## 5.1 By design goal

| Goal                                              | Modality        | Tool of first choice                       | Backup                          |
|---------------------------------------------------|-----------------|--------------------------------------------|---------------------------------|
| De-novo small-molecule generation in a pocket     | Small mol       | **DiffSBDD** (§1.4)                        | Pocket2Mol, TargetDiff          |
| Lead optimization (SAR-aware)                     | Small mol       | **REINVENT4** (§1.5)                       | DrugAssist (LLM), AiZynthFinder |
| Virtual screening of >1 M compounds               | Small mol       | **Chemprop** surrogate + **Vina**          | DeepChem, ConPLex               |
| ADMET prediction                                  | Small mol       | **ADMET-AI** (§1.6)                        | Chemprop, SwissADME             |
| Pose prediction (binder of known SMILES)          | Small mol       | **DiffDock** (§1.8) + Vina rescore         | EquiBind, NeuralPLexer          |
| Binding-affinity scoring                          | Small mol       | **AEV-PLIG** (§1.8b)                       | PSICHIC, Boltz-2                |
| De-novo mini-protein binder                       | Protein         | **RFdiffusion** + **ProteinMPNN** + AF2    | Chroma + LigandMPNN             |
| Mini-protein with known motif scaffold            | Protein         | **RFdiffusion** motif scaffolding mode      | BindCraft (one-shot AF2)         |
| Inverse folding (sequence design on backbone)     | Protein         | **ProteinMPNN** (§2.5)                     | LigandMPNN, ESM-IF              |
| Affinity maturation / optimization                | Protein         | **EvoProtGrad** (§2.6)                     | LaMBO, ODBO                     |
| Protein-protein binding ΔΔG                       | Protein         | **PPIformer / Graphinity / GearBind**      | DiffAffinity, RDE-PPI           |
| Protein–ligand complex (no docking)               | Protein         | **AlphaFold3** / **Boltz-2**               | NeuralPLexer, RoseTTAFold-AA    |
| Cyclic / macrocyclic peptide                      | Peptide         | **RFpeptides** / **CycleDesigner**         | PepFlow                         |
| Linear peptide binder                             | Peptide         | **PepMLM** / **PepFlow**                   | DiffPepBuilder                  |
| Antibody CDR redesign                             | Antibody        | **DiffAb** / **dyMEAN** (§4.5)             | RFantibody, AbDiffuser          |
| Antibody affinity maturation                      | Antibody        | **Graphinity** (§4.6)                      | AbMAP, EvoBind                  |
| Antibody humanization                             | Antibody        | **BioPhi** / **HuDiff** (§4.7)             | Sapiens                         |
| Nanobody CDR3 design                              | Nanobody        | **RFantibody** (§3.4)                      | DiffAb (single-chain mode)      |
| Aptamer SELEX in-silico                           | RNA aptamer     | **RaptGen** (§5.5)                         | AptaTrans                       |
| Aptamer 3D structure                              | RNA             | **RhoFold+** (§5.3)                        | trRosettaRNA2, DRfold           |
| Aptamer binding affinity                          | RNA             | **CoPRA** (§5.7)                           | RPINet+, AptaTrans              |
| End-to-end agentic discovery                      | Any             | **Robin** (§6.6) for therapeutics, **Biomni** for general bio | ProtAgents (proteins), ChemCrow (small mol) |

## 5.2 By compute budget

| Budget                              | What you can attempt                                                              |
|-------------------------------------|-----------------------------------------------------------------------------------|
| **No GPU (laptop CPU)**             | Sanity checks; AutoDock Vina (small libs); RDKit-only ADMET; reading the catalogue|
| **1× consumer GPU (RTX 30/40)**     | Full small-molecule pipeline at ~1 k compounds/day; RFdiffusion for ~20 designs/h |
| **1× A100 (40/80 GB)**              | RFdiffusion + AF2 for 100s of designs/day; DiffDock for 10 k poses/day            |
| **Cluster (8× A100 / H100)**        | Industrial-scale screens; antibody ensemble design; long-trajectory MD            |
| **HPC + Apptainer**                 | Same as cluster, with reproducibility & multi-user safety                         |

## 5.3 By trustworthiness of single-tool output

| Tool / output                           | Trust as a single number?     |
|-----------------------------------------|-------------------------------|
| AlphaFold pLDDT                         | ✅ for fold confidence; ❌ for affinity |
| AF2 ipTM / PAE @ interface              | ✅ for "is this complex real?"|
| Vina docking score                      | ❌ — always combine with another scorer |
| DiffDock confidence                     | ❌ — pose-quality, not affinity |
| AEV-PLIG / PSICHIC affinity             | ⚠️ ranking yes; absolute ΔG no |
| PPIformer / Graphinity ΔΔG              | ⚠️ relative changes, not absolute |
| LLM-agent's "best candidate" pick       | ❌ — always run a manual round-2 |

## 5.4 Sanity-check checklists

Print these and tick before each campaign.

### Before generation
- [ ] Target structure has pLDDT ≥ 70 across the binding region.
- [ ] PDBFixer cleaned, hydrogens added, ligands/water resolved.
- [ ] Pocket / hotspot residues identified and noted.
- [ ] Conformer is the relevant biological state.
- [ ] GPU + container smoke-tests passing.

### Before wet-lab handoff
- [ ] Multiple scoring functions agree on the shortlist.
- [ ] Designs cluster into ≥10 distinct families (sequence/structure).
- [ ] Developability filters applied (Lipinski/ADMET for small mol; SAP/Tm/humanness for proteins).
- [ ] Closest natural homolog identified — you know whether you're "novel".
- [ ] Negative-control designs included (random sequences / scrambled SMILES).

## 5.5 Where to read deeper

- For **method intuition**: original papers cited in the main `README.md` next to each tool.
- For **practical pipelines**: this guide.
- For **agentic / autonomous loops**: Section 6 of the main README + CASP-style benchmarks (CASP15/16, ProteinGym, PoseBusters).
- For **wet-lab integration**: outside this repo's scope. Talk to a chemist or biochemist.

If a tool you need isn't covered, open an issue against the repository — the catalogue grows by demand.
