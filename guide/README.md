# A Hitchhiker's Guide to Deep-Learning Based Biomolecular Binder Design

> "Don't panic." — Douglas Adams

A practitioner's companion to the tool catalogue. Where the main `README.md` answers *"what tools exist?"*, this guide answers the harder questions:

- **Which tool do I pick at each stage?**
- **In what order do I run them?**
- **What does a working end-to-end pipeline actually look like?**
- **What are the failure modes, and how do I notice when I've fallen into one?**

## Audience

You have a PDB structure (or a target name) and a goal — a small molecule, peptide, antibody, or RNA aptamer that binds it. You're comfortable on the command line, can read Python, and have at least a hazy memory of undergraduate biochemistry. You don't need to be an ML researcher.

## How to read this guide

Each chapter is **goal-oriented**, not tool-oriented. Pick the chapter that matches your binder modality and follow it top-to-bottom. The decision matrix in Chapter 5 is the fastest way in if you're not sure where to start.

## Table of contents

| #  | Chapter                                                              | When to read it                                       |
|----|----------------------------------------------------------------------|-------------------------------------------------------|
| 1  | [Getting Started](01-getting-started.md)                             | First time here, or unsure what shape your problem is |
| 2  | [Designing Small-Molecule Binders](02-small-molecules.md)            | Drug-like ligands, fragments, PROTACs                 |
| 3  | [Designing Protein & Peptide Binders](03-protein-peptide-binders.md) | Mini-binders, scaffolds, peptides                     |
| 4  | [Antibodies, Nanobodies & RNA Aptamers](04-antibodies-nanobodies-rna.md) | Therapeutic antibodies, VHH, RNA aptamers          |
| 5  | [Tool-Selection Decision Matrix](05-decision-matrix.md)              | "I just need a fast answer to 'what tool?'"           |

## Conventions

- **Bolded numbers** in chapters (e.g. **§2.4**) refer to subsections of the main catalogue `README.md`. Look there for tool-by-tool install/usage details.
- **Containers** referenced in commands assume you've built the recipes in `../containers/`. If you haven't, the in-text commands work against host conda envs equally well.
- **"Worked example"** boxes are tested end-to-end against publicly available PDBs (1QYS, 1IEP, 4HHB) so you can reproduce them.

## What this guide is not

- **Not a textbook.** Read Anandakrishnan & Onufriev for biophysics, Engel for medicinal chemistry. We focus on the AI-driven workflow.
- **Not a leaderboard.** Tool recommendations are based on practitioner experience and recent benchmarks (CASP15/16, PoseBusters, ProteinGym), not bench-scale wet-lab validation. Always verify on your own target.
- **Not exhaustive.** When two tools do the same thing, we recommend one — usually the better-maintained, better-documented option. The catalogue has the full list.

## Contributing

If you've followed this guide and found a step that didn't reproduce, a tool that's been deprecated, or a better alternative — open an issue or PR. The goal is *fewer dead links and surprises* than the average research-lab onboarding doc.
