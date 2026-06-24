# Chapter 2 — Designing Small-Molecule Binders

You want a drug-like molecule that binds your target protein. This chapter walks the full pipeline from a clean target structure to a ranked, diverse, developability-aware shortlist.

## 2.1 Decision tree before you start

```
Do you have a known active scaffold?
│
├─ Yes ──► Lead optimization route (§2.4)
│           – Fragment growing / linking
│           – Property optimization (REINVENT4, DrugAssist)
│
└─ No ───► De novo discovery route (§2.3)
            – Pocket prediction → SBDD (DiffSBDD, Pocket2Mol, TargetDiff)
            – Virtual screening of ChEMBL/Enamine REAL
```

The two routes diverge at the *generation* stage but reconverge at *scoring* and *filtering*. Sections 2.5+ apply to both.

## 2.2 Target prep recap

Coming from Chapter 1 you should have:

- `target_clean.pdb` — fixed, protonated, hydrogens added.
- `pockets/` — P2Rank predictions, top-ranked pocket centre coordinates noted.
- A defined search box for docking (`center_x/y/z`, `size_x/y/z` in Å, typically 22 Å cube).

If the pocket is *cryptic* (closed in the apo structure), use **PocketMiner** (§1.3) on an MD ensemble or run **AlphaFlow / BioEmu** to get a pocket-open conformer.

## 2.3 De-novo discovery route

### 2.3.1 Structure-based generation (recommended)

For most targets with a defined pocket, structure-based de-novo generation beats virtual screening on diversity per CPU-hour.

**Tool of choice: DiffSBDD (§1.4)** — diffusion model conditioned on the pocket atoms.

```bash
# Inside the small-molecule container
cd /work
python /opt/DiffSBDD/sample.py \
    --pocket target_clean.pdb \
    --num_samples 1000 \
    --out_dir generated/ \
    --batch_size 32
```

Alternative: **Pocket2Mol** (§1.4) for a more conservative, atom-by-atom autoregressive sampler. Pocket2Mol tends to give synthesisable molecules; DiffSBDD gives more chemical diversity. Try both.

### 2.3.2 Virtual screening route

When the budget is large but you need synthesisable molecules *yesterday*, screen Enamine REAL (~50 B compounds) using a fast surrogate.

```bash
# 1. Train a Chemprop model on a small assay seed (or use a published one)
chemprop train --data-path seed_actives.csv \
    --task-type regression --target-columns pIC50 \
    --save-dir models/pic50

# 2. Predict over a 1M REAL subset
chemprop predict --test-path real_1M.smi \
    --model-path models/pic50/fold_0/model_0/model.pt \
    --preds-path real_predicted.csv

# 3. Take the top 10 000 and dock with Vina (§1.8)
head -10000 ranked_smiles.txt | parallel -j 8 vina --receptor target.pdbqt --ligand {}.pdbqt ...
```

For larger libraries, **DeepScreen** / **RoseTTAFold All-Atom** rescoring becomes the bottleneck — distribute across nodes via Apptainer.

## 2.4 Lead-optimization route

You have a hit. Improve potency, ADMET, or both.

### 2.4.1 Iterative property optimization

**Tool of choice: REINVENT4 (§1.5)** — RL-based scaffold-constrained generation.

```bash
reinvent --config reinvent_config.toml
```

A minimal `reinvent_config.toml` for affinity-driven optimization (against a Vina docking surrogate) and ADMET filters:

```toml
[parameters]
prior_file       = "priors/reinvent.prior"
agent_file       = "priors/reinvent.prior"
batch_size       = 128

[scoring_function]
name = "affinity-and-admet"
[[scoring_function.components]]
component_type   = "vina_dock"
weight           = 1.0
[[scoring_function.components]]
component_type   = "qed"
weight           = 0.5
[[scoring_function.components]]
component_type   = "sa_score"
weight           = 0.3
```

### 2.4.2 Conversational tweaks (DrugAssist)

For one-off, expert-driven tweaks ("reduce logP by ~1, keep the carboxylic acid, suggest 5 alternatives"), **DrugAssist** (§6.2) is faster than re-running RL.

## 2.5 Scoring & ranking

**Always score with multiple functions and only trust the consensus.** A reasonable stack:

| Score                | What it measures                       | When to trust it                           |
|----------------------|----------------------------------------|--------------------------------------------|
| Vina / Smina         | Classical empirical                    | Fast triage; not for ranking the top 5%    |
| AutoDock-GPU         | Same physics, GPU-accelerated          | High-throughput rescoring                  |
| DiffDock confidence  | Generative pose confidence             | Pose quality, not affinity                 |
| AEV-PLIG (§1.8b)     | GNN trained on PDBbind, structure-aware| Affinity ranking of top hits               |
| PoseBusters (§1.8)   | Physical sanity (clashes, geometry)    | Reject — never accept — based on PB        |

Rule of thumb: take the union of "top 10% by Vina" and "top 10% by AEV-PLIG", reject anything that fails PoseBusters, and you're left with the *consensus shortlist*.

## 2.6 Filtering for developability

A molecule that binds but can't be a drug wastes everyone's time.

```python
from rdkit import Chem
from rdkit.Chem import Descriptors, rdMolDescriptors

def passes_lipinski(smi: str) -> bool:
    mol = Chem.MolFromSmiles(smi)
    return all([
        Descriptors.MolWt(mol)        <= 500,
        Descriptors.MolLogP(mol)      <= 5,
        rdMolDescriptors.CalcNumHBD(mol) <= 5,
        rdMolDescriptors.CalcNumHBA(mol) <= 10,
    ])
```

For richer ADMET, run **ADMET-AI** (§1.6) over the shortlist. Reject molecules with predicted hERG inhibition probability > 0.5, AMES toxicity > 0.5, or hepatotoxicity > 0.5 unless you have a *very* good reason.

## 2.7 Diversification

Cluster the survivors before ordering DNA / synthesis quotes. Otherwise you'll buy 50 near-duplicates.

```bash
# Tanimoto-based clustering at 0.5 similarity cutoff
python - <<'PY'
from rdkit import Chem
from rdkit.Chem import AllChem, DataStructs
from sklearn.cluster import AgglomerativeClustering
import numpy as np, csv

mols = [Chem.MolFromSmiles(l.strip()) for l in open("survivors.smi")]
fps  = [AllChem.GetMorganFingerprintAsBitVect(m, 2, 2048) for m in mols]
sim  = np.array([[DataStructs.TanimotoSimilarity(a, b) for b in fps] for a in fps])
labels = AgglomerativeClustering(distance_threshold=0.5, n_clusters=None,
                                 metric="precomputed", linkage="average").fit_predict(1 - sim)
with open("diverse.smi", "w") as f:
    for cluster_id in set(labels):
        rep = next(i for i, l in enumerate(labels) if l == cluster_id)
        f.write(Chem.MolToSmiles(mols[rep]) + "\n")
PY
```

Aim for 40–80 diverse representatives going to wet-lab.

## 2.8 Worked example: TYK2 inhibitors

A reproducible end-to-end run against PDB **4GIH** (TYK2 JH2 pseudokinase domain), a widely benchmarked target:

```bash
# Inside small-molecule container, /work mounted

# 1. Pocket centre from P2Rank (already run in target prep): ( 6.5, 21.2, 14.0 )
# 2. De-novo generation
python /opt/DiffSBDD/sample.py --pocket 4gih_clean.pdb --num_samples 2000 --out_dir gen/

# 3. Filter by Lipinski + QED > 0.5
python filter_lipinski_qed.py gen/molecules.smi > pre_dock.smi  # ~600 survivors

# 4. Dock with Vina
parallel -j 8 'mk_prepare_ligand.py -i {} -o lig.pdbqt && \
               vina --receptor 4gih.pdbqt --ligand lig.pdbqt \
                    --center_x 6.5 --center_y 21.2 --center_z 14.0 \
                    --size_x 22 --size_y 22 --size_z 22 \
                    --out poses/{#}.pdbqt --log logs/{#}.log' :::: pre_dock.smi

# 5. Re-rank top 60 with AEV-PLIG (§1.8b), reject PoseBusters failures
python rerank_aevplig.py poses/ > ranked.csv

# 6. Cluster to ~40 representatives, run ADMET-AI, ship to chemistry
python diversify_and_admet.py ranked.csv > shortlist.csv
```

Expected wall-clock on a single RTX 4090: ~6 hours total. ~30% of the shortlist will dock with sub-µM-equivalent Vina scores; the wet-lab hit rate among published TYK2 benchmarks runs ~5–15%.

## 2.9 What the agentic stack changes (Section 6)

Tools like **ChemCrow**, **DrugAgent**, and **CoScientist (ITMO)** automate steps 2.3–2.6 above — they pick the generator, run the docks, do the ADMET filtering, and present a ranked shortlist. They are not yet better than a careful human; they are *much* faster for prototyping. Use them for round 1, then take the survivors into the manual pipeline for round 2.
