# Chapter 4 — Antibodies, Nanobodies & RNA Aptamers

These three modalities share a common feature — *narrow* binding regions (CDRs for antibodies, single VHH loops for nanobodies, secondary-structure motifs for aptamers) — that change the design strategy substantially compared to small molecules or de-novo proteins.

## 4.1 Antibodies (Section 4)

You have a target and you want a full-length antibody (IgG VH/VL) or an Fv against it. The usual move is **CDR redesign on a published framework** rather than full de-novo.

### Pipeline

```
Pick framework  →  Predict structure  →  CDR design  →  Affinity maturation
   (germline)       (ImmuneBuilder)       (DiffAb /         (Graphinity / AbMAP)
                                            DyMEAN)
                                                   →  Humanize / developability
                                                       (BioPhi / HuDiff)
```

### Tool choices

| Step                              | Tool of choice                     | Why                                                  |
|-----------------------------------|-------------------------------------|------------------------------------------------------|
| Framework selection               | OAS / SAbDab (§0.4)                 | Pick a *clinical-stage* framework (low immunogenicity)|
| Structure prediction              | **ImmuneBuilder** (§4.2)            | 100× faster than AF2, antibody-specific accuracy    |
| Numbering                         | **ANARCI** (§4.3)                   | The standard                                         |
| De-novo CDR design                | **DiffAb** or **dyMEAN** (§4.5)     | Both are AF-quality; dyMEAN is faster                |
| Affinity maturation               | **Graphinity** (§4.6)               | EGNN-based ΔΔG, well-validated on AB-Bind            |
| Humanization                      | **BioPhi / HuDiff** (§4.7)          | If you started from a non-human framework            |
| Developability                    | **TAP / SAP / DeepSP**              | Aggregation, polyspecificity                          |

### Typical campaign

1. Pull 50–100 CDR-grafted starts from SAbDab against your epitope class.
2. Predict structures with ImmuneBuilder (~20 min for 100 antibodies on RTX 4090).
3. Run DiffAb to redesign H3 against the target (paratope-conditional sampling).
4. Score the top 1 000 with Graphinity ΔΔG vs. parent.
5. Filter survivors through BioPhi humanness, TAP / SAP developability.
6. Hand 20–40 to the wet-lab.

### Common traps

- **Not checking H3 length distribution.** DiffAb tends to oversample short H3s — bias correction is needed.
- **Ignoring polyspecificity.** A high-affinity binder that also binds heparin will fail in vivo. Run TAP / DeepSP.
- **Designing on the wrong framework.** A murine framework is a fast path to humanization headaches. Start from clinical-stage humanized scaffolds.

## 4.2 Nanobodies (Section 3)

Single-domain VHH antibodies. Smaller, easier to express, but the design space is also smaller because there's only one chain.

### Pipeline

```
Library / pre-trained   →   Structure predict   →   CDR3 design   →   Humanize   →   Stability
(NaturalAntibody, OAS)      (NanoNet, IgFold)        (RFantibody)       (BioPhi)        (TEMPRO)
```

### Tool choices

| Step                    | Tool of choice                         | Note                                                    |
|-------------------------|----------------------------------------|---------------------------------------------------------|
| Sequence model          | **AbLang2** or **NanoBody-LM** (§3.1)  | Use for fitness landscape & sequence completion          |
| Structure prediction    | **NanoNet** or **IgFold** (§3.2)       | NanoNet is nanobody-specific, faster; IgFold is general  |
| Numbering               | **ANARCI / AbNumber** (§3.3)           | —                                                        |
| De-novo CDR3 design     | **RFantibody** (§3.4)                  | Best published wet-lab hit rate as of 2026               |
| Humanization            | **BioPhi / Sapiens** (§3.6)            | Camelid → human substitutions                            |
| Thermal stability       | **TEMPRO** (§3.7)                      | Important — VHHs vary 30+ °C in Tm                       |
| Affinity optimization   | **EvoProtGrad** (§2.6)                 | Sequence-only directed evolution                         |

### Worked example: SARS-CoV-2 RBD nanobody

Hotspots from public structural studies of class-1 RBD nanobodies (e.g. Ty1):

```bash
# 1. CDR3 redesign on Ty1 framework against RBD
python /opt/RFantibody/sample.py \
    --target rbd_clean.pdb --framework ty1.pdb \
    --hotspots A484,A486,A493 --num_designs 500

# 2. NanoNet refold + filter for pLDDT > 80
python nanobody_filter.py designs/ --min-plddt 80 > pass_fold.csv

# 3. TEMPRO Tm prediction; reject < 55 °C
python tempro_score.py pass_fold.csv > pass_stable.csv

# 4. BioPhi humanness; reject < 0.8
python biophi_filter.py pass_stable.csv > shortlist.csv
```

## 4.3 RNA aptamers (Section 5)

A different beast: *no protein scaffolds*, much harder structure prediction, fewer well-validated tools. Treat the field as ~3 years behind protein binder design.

### Pipeline

```
Pick scaffold class   →   In-silico SELEX / generation   →   2D / 3D fold   →   Score binding
(hairpin, G-quadruplex)    (RaptGen, AptaDiff, AptaTrans)     (RhoFold+,         (CoPRA, RNAmigos2,
                                                              trRosettaRNA2)      AptaTrans)
```

### Tool choices

| Step                | Tool of choice                          | Note                                                      |
|---------------------|-----------------------------------------|-----------------------------------------------------------|
| Sequence LM         | **RNA-FM** or **RiNALMo** (§5.1)        | RiNALMo (650M) is currently strongest                     |
| In-silico SELEX     | **RaptGen** (§5.5)                      | VAE-based; generates aptamer libraries                    |
| De-novo generation  | **AptaDiff** (§5.6)                     | Diffusion; competitive with RaptGen                       |
| 2D structure        | **EternaFold** or **MXfold2** (§5.2)    | EternaFold for thermodynamic; MXfold2 for ML              |
| 3D structure        | **RhoFold+** or **trRosettaRNA2** (§5.3)| RhoFold+ better for short aptamers (<80 nt)               |
| Aptamer-target dock | **HADDOCK3 / NPDock** (§5.4)            | NPDock specifically for RNA-protein                       |
| Binding affinity    | **CoPRA** (§5.7)                        | Dual-LM ΔG; the strongest aptamer affinity scorer in 2025 |
| Inverse folding     | **RhoDesign / RiboDiffusion** (§5.6)    | 3D-conditioned sequence design                            |

### Reality check

Aptamer design is much less reliable than protein design. Plan for higher round-counts in the wet-lab, and don't trust any single ΔG predictor — always cross-validate with at least one MD simulation per shortlisted aptamer.

## 4.4 What the agentic stack changes

**Biomni** (§6.6) is currently the most flexible general-purpose biomedical agent for these modalities — it has tools for CRISPR-screen design, scRNA-seq annotation, and a growing antibody-design tool surface. Use it as a *literature-aware planner*, then run the actual generation manually using the chapter-specific pipelines.

**CRISPR-GPT** (§6.5) doesn't help with binder design directly, but if your target validation needs a CRISPR screen of resistance/sensitivity genes, it cuts that planning step from days to hours.
