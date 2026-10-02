# Virtual Screening of HMG-CoA Reductase (HMGR, UniProt P04035) Inhibitors
### Report outline / draft skeleton

*Fill in bracketed placeholders as results come in. Section order follows the logic of the project, not necessarily the final page order — some sections can be merged for length (e.g. 3+4 into one "Methods" section with subheadings).*

---

## 1. Introduction

- Biological/pharmacological context: HMGR catalyzes the rate-limiting step in cholesterol biosynthesis; it is the target of statins. Briefly justify why it's a well-studied, pharmacologically validated target (one short paragraph, cite UniProt P04035 and ChEMBL target CHEMBL402).
- Restate the assignment objective: retrieve the maximum number of actives among top-ranked compounds from a set of 151 actives / 8,324 inactives, using ligand-based, structure-based, and consensus approaches.
- One paragraph previewing your overall strategy (ligand-based screening on the full library → docking on a representative subsample → consensus/ML model → comparative evaluation). This is your "roadmap" paragraph — write it last, once the pipeline is finalized.

## 2. Data curation

- Source of actives/inactives (.smi files provided), and matching against ChEMBL (target CHEMBL402) for IC50/activity confirmation.
- Curation steps: canonicalization, salt/fragment stripping (largest-fragment rule), duplicate removal, [state how many molecules were excluded and why].
- Activity threshold used to define active/inactive (state the IC50 cutoff, e.g. ≤ 1 µM, and cite that this follows the convention used in [professor's article]).
- Final counts: N actives, N inactives after curation.

## 3. Ligand-based screening

- **Reference set**: describe your final choice (e.g. diverse subset of ~20 known actives selected via clustering, held out from evaluation; optionally combined with PDB co-crystallized ligands 4HI/HUX/etc.).
- **Fingerprints & coefficients**: Morgan/ECFP4 (2048 bits, radius 2) and MACCS keys (167 bits), Tanimoto (and/or Dice) similarity.
- **Scoring rule**: max-similarity (nearest-neighbor) to the reference panel, per candidate.
- **Circularity control**: explain the train/held-out split of actives used as references vs. evaluated candidates, and why this matters (state the risk of circular evaluation if references overlap with the test set).
- **Result**: ROC curve + AUC, enrichment curve, EF1%/EF5% for ligand-based screening alone, evaluated on the *full* library (all inactives + held-out actives). [Insert figure/table.]
- Brief comparison: Morgan vs. MACCS performance, if both were computed.

## 4. Structure-based screening (docking)

- **Target structure**: which PDB entry(ies) used (e.g. 3CCW, ligand 4HI), retrieval from RCSB, rationale for choice (resolution, ligand relevance, etc.).
- **Receptor preparation**: steps taken (water removal, `prepare_receptor4.py`/MGLTools, charge assignment), and note any issues encountered and how resolved (e.g. mol2→PDB conversion fix).
- **Docking box**: center coordinates and size, derived from the co-crystallized ligand position; software used (Smina/Vina), exhaustiveness setting.
- **Ligand preparation**: SMILES → 3D conversion pipeline (state tool used — RDKit/Meeko or OpenBabel), attrition (state how many of the 302 selected molecules failed 3D generation and were dropped, and whether failures were roughly proportional between actives/inactives).
- **Docked subset**: state final N actives / N inactives actually docked (justify the random/matched subsampling of inactives given computational constraints — full-library docking of 8,324 inactives was not feasible in the available time).
- **Result**: enrichment curve (log fraction-tested axis, per-compound resolution) and ROC-AUC for raw docking score alone, evaluated on the docked subset only. [Insert figure/table.]

## 5. Consensus / machine-learning scoring

- **Rationale**: cite that raw docking scores alone often show limited discriminative power (reference your own Vina-alone result, and note this is consistent with reported comparisons of individual scoring functions vs. consensus methods in the literature).
- **Features used**: similarity score + docking score (+ any additional descriptors if added).
- **Model**: algorithm used (logistic regression baseline; optionally a second model, e.g. random forest, for comparison), train/test split strategy (stratified, [state ratio]).
- **Result**: ROC-AUC, enrichment curve, EF1%/EF5% for the consensus model, evaluated on the held-out test portion of the docked subset. [Insert figure/table.]

## 6. Comparative evaluation

- **Single combined figure**: ROC curves (or enrichment curves) for ligand-based-only, docking-only, and consensus overlaid — this is the central result of the report.
- Summary table: method | AUC | EF1% | EF5% | notes on evaluation scope (full library vs. docked subset).
- Explicit discussion: does consensus outperform either individual method? Quantify the improvement.

## 7. Selected hits

- Table of top-N (e.g. 10–15) compounds from your best-performing method: ChEMBL ID, structure (2D depiction), similarity score, docking score, consensus score, true label.
- Optional: highlight a case where consensus recovered a true active that either individual method ranked poorly — good illustration of why combining approaches helps.

## 8. Discussion & limitations

- **Evaluation scope**: ligand-based results reflect the full library; structure-based/consensus results are scoped to a representative subsample due to docking cost — state this clearly as a controlled, deliberate choice, not an oversight.
- **Analogue/decoy composition**: note that your inactive set includes real experimentally inactive compounds, some structurally close to actives — argue this makes your benchmark harder (and more meaningful) than one built from property-matched-but-dissimilar decoys.
- **Generalizability**: whether or not you tested against an external public benchmark (DUD-E/DEKOIS) — state this explicitly either as a validation result or as an acknowledged limitation/future work.
- **Attrition**: molecules lost at each curation/conversion step, and whether loss was balanced across classes.
- Any other methodological choices worth flagging (fingerprint choice, single vs. ensemble docking structure, etc.).

## 9. Conclusion

- One paragraph: which approach(es) performed best, whether consensus met the assignment's goal of maximizing active recovery in top-ranked compounds, and the main takeaway for future screening on this target.

---

### Figures/tables checklist
- [ ] Ligand-based enrichment curve (log-x)
- [ ] Docking-only enrichment curve (log-x)
- [ ] Consensus enrichment curve (log-x)
- [ ] Combined overlay of all three
- [ ] ROC curves (same three, overlaid)
- [ ] Summary metrics table (AUC / EF1% / EF5%)
- [ ] Top-hits table
- [ ] Workflow diagram (optional, schematic of the full pipeline)
