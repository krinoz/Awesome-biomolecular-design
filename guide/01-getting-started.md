# Chapter 1 — Getting Started

Before you fire up RFdiffusion or DiffDock, take 20 minutes to answer a handful of questions about your target. These answers determine which chapter to read next, and — more importantly — what failure modes to watch for.

## 1.1 Frame the problem

| Question                                                          | Why it matters                                                                                                  |
|-------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|
| **What modality am I designing?**                                 | Picks the chapter (small mol vs protein vs antibody vs aptamer).                                                |
| **Do I have an experimental structure of the target?**            | If not, you'll spend Chapter 1.5 predicting one before doing anything else.                                     |
| **Do I know the binding site?**                                   | "Where on the protein?" determines whether you can use motif-scaffolding (RFdiffusion), targeted docking (Vina, DiffDock), or have to predict the site first (P2Rank, PocketMiner). |
| **What's my throughput target?**                                  | 10 designs vs 10 000 designs leads to *very* different tool choices (RFdiffusion ↔ ColabDesign hallucination, DiffDock ↔ Vina). |
| **Can I do wet-lab validation, or am I purely *in silico*?**      | If the answer is *in silico only*, your scoring function needs to be conservative — never trust a single docking score. |
| **What computational resources do I have?**                       | RTX 4090 vs A100 vs CPU-only constrains which models will even run.                                             |

Write the answers down. They will save you hours.

## 1.2 The universal pipeline shape

Almost every binder design project follows the same five stages:

```
   ┌─────────────┐   ┌──────────┐   ┌──────────┐   ┌────────────┐   ┌────────────┐
   │  Target     │ → │ Design / │ → │ Score &  │ → │ Filter &   │ → │ Validate   │
   │ preparation │   │ generate │   │ rank     │   │ diversify  │   │ (wet-lab)  │
   └─────────────┘   └──────────┘   └──────────┘   └────────────┘   └────────────┘
```

Read each subsequent chapter in this shape. You'll see the same five boxes filled with different tools depending on modality.

## 1.3 The five most common failure modes

Spending a week generating thousands of designs is fine. Discovering on day eight that the entire batch is unfoldable, undruggable, or boring is not. Watch for these:

1. **Garbage in, garbage out.** If your target structure is a low-confidence AF2 prediction in a flexible region, no design tool will save you. Inspect pLDDT, B-factors, and missing residues before you start.
2. **Over-fit to the docking score.** A single Vina score difference of 0.5 kcal/mol is noise. Always use multiple scoring functions or, better, a re-scoring pass with a different physics (e.g. MM/GBSA, AEV-PLIG).
3. **Forgetting developability.** A protein binder with a hydrophobic patch large enough to make AlphaFold confident often aggregates in the tube. Check SAP, SASA, and pI before ordering DNA.
4. **Mode collapse.** Generative models love to converge on the same scaffold. Diversify *before* you score; cluster designs by sequence/structure similarity (`mmseqs easy-cluster`, `foldseek easy-cluster`) and keep representatives.
5. **Confusing in-distribution success for novelty.** RFdiffusion can hallucinate an excellent binder against a target that's already in its training set. Always check by looking up the closest natural homolog (Foldseek, BLAST) before claiming novelty.

## 1.4 Sanity-check your environment

If you're using the containers from `../containers/`:

```bash
docker run --rm --gpus all awesome-biomol/protein-design:latest smoke-test
docker run --rm --gpus all awesome-biomol/small-molecule:latest smoke-test
```

Both should end with `[smoke] all checks passed.` If you're running on host conda, replicate `containers/<stack>/environment.yml` and run the smoke-test scripts directly.

## 1.5 Target preparation in 5 minutes

A good target structure is the single biggest determinant of downstream success. The minimum-viable prep:

```bash
# 1. Predict the target if you don't have a crystal/cryo structure
colabfold_batch target.fasta target_pred/ --num-models 5 --templates

# 2. Pick the highest-pLDDT model and clean it
python -m pdbfixer target_pred/best.pdb \
    --add-atoms heavy --add-residues --keep-heterogens water \
    --output target_clean.pdb

# 3. Inspect: plot per-residue pLDDT, mark low-confidence regions
python - <<'PY'
import biotite.structure.io.pdb as pdb
import matplotlib.pyplot as plt
struct = pdb.PDBFile.read("target_clean.pdb").get_structure(model=1)
plt.plot([a.b_factor for a in struct if a.atom_name == "CA"])
plt.axhline(70, color="red", ls="--", label="pLDDT 70 (low confidence)")
plt.legend(); plt.savefig("plddt.png")
PY

# 4. Identify pockets if you don't already know the site
prank predict -f target_clean.pdb -o pockets/   # P2Rank, §1.3
```

If your target has a region with pLDDT < 50 *inside* the candidate binding pocket, **stop**. Get a better structure (cryo-EM, AF3 with the right MSA depth, or run `AlphaFlow` from §2.2b to get an ensemble) before you waste GPU hours.

## 1.6 Where to next

| Your modality                  | Read                                            |
|--------------------------------|-------------------------------------------------|
| Small molecule / drug-like     | [Chapter 2 — Small Molecules](02-small-molecules.md)            |
| Mini-protein, peptide, scaffold| [Chapter 3 — Protein & Peptide Binders](03-protein-peptide-binders.md)  |
| Antibody, nanobody, RNA aptamer| [Chapter 4 — Antibodies, Nanobodies & RNA](04-antibodies-nanobodies-rna.md) |
| Still not sure                 | [Chapter 5 — Decision Matrix](05-decision-matrix.md) — pick by goal      |
