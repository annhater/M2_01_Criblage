> Vous disposez de 151 composés actifs et 8324 composés inactifs comme inhibiteurs d’HMGR (HMG-CoA reductase), fournis sous forme de fichiers .smi.
> La cible correspond à l’UniProt ID P04035.
> Votre objectif est de mettre en place une procédure de criblage virtuel permettant de retrouver le maximum d’actifs parmi les composés les mieux classés par votre méthode.
> Pour cela, vous pouvez mobiliser les approches vues en M1 :
> 	- Ligand-based screening : calcul de similarité avec des empreintes moléculaires (e.g. Morgan, MACCS) et coefficients (Tanimoto, Dice), recherche de similarité par rapport aux ligands co-cristallisés.
> 	- Structure-based screening : docking moléculaire sur une ou plusieurs structures expérimentales de la protéine (à récupérer via RCSB ou UniProt), éventuellement suivi d’un rescoring.
> 	- Combinaison d’approches : consensus scoring entre ligand-based et structure-based.
> Vous êtes encouragés à être créatifs dans la conception de votre procédure. Pensez à justifier vos choix méthodologiques et à évaluer vos résultats (par exemple via enrichissement factor, ROC-AUC, ou précision/rappel dans les top composés).

1. La cible: UniProt ID P04035
> HMDH_Human: Catalyzes the conversion of (3S)-hydroxy-3-methylglutaryl-CoA (HMG-CoA) to mevalonic acid, the rate-limiting step in the synthesis of cholesterol and other isoprenoids, thus plays a critical role in cellular cholesterol homeostasis (PubMed:[21357570](https://www.uniprot.org/citations/21357570), PubMed:[2991281](https://www.uniprot.org/citations/2991281), PubMed:[36745799](https://www.uniprot.org/citations/36745799),


I read your professor's article — and it's a great match: it's literally about this HMGR case study (UniProt P04035, ChEMBL402, PDB 3CCW/1HW8), so your dataset is almost certainly built following this exact protocol. Here's how I'd reorganize your plan, keeping the article's four-stage logic but scaled down to something you can realistically finish for a class project.


1. **Ligand-based similarity isn't just a filter — it's also a standalone screening method you should evaluate on its own.** The article uses it that way (similarity to the co-crystallized ligand ranks the whole library), then *separately* uses docking, then combines both in consensus scoring. If you only use it to pre-filter, you lose the ability to compare "ligand-based alone" vs "structure-based alone" vs "consensus" — which is exactly the kind of comparison your assignment asks for.

2. **Docking all 8,475 molecules may not be realistic in limited computer-room time.** The article's own protocol takes "hours to almost a day" per stage with dedicated infrastructure. For you, the fix isn't to blindly filter with ligand-based scores (that would bias your evaluation set), but to dock a **stratified, balanced subsample**: all 151 actives + a random (or property-matched) sample of inactives, e.g. 300–750, keeping the active ratio low but not absurdly so. You can always mention in your report that full-library docking was infeasible given constraints — that's a legitimate, honest methodological note.

## Reorganized pipeline

**1. Data curation**
- Parse both `.smi` files, canonicalize SMILES (RDKit), remove salts/duplicates.
- Pull IC50/activity data from ChEMBL for target `CHEMBL402` (matches UniProt P04035) mainly to (a) sanity-check your active/inactive labels against a potency threshold (the article uses ≤1 µM), and (b) later correlate docking/ML scores against real potency if you want a regression angle, not just classification.

**2. Ligand-based screening**
- Get the co-crystallized ligand(s) from the PDB structures (3CCW → ligand HUX, or 1HW8 → ligand 4HI, both human HMGR catalytic domain).
- Compute fingerprints for every compound: **Morgan/ECFP4 (RDKit `GetMorganFingerprintAsBitVect`, 2048 bits, radius 2)** — this is what the article uses — and optionally **MACCS keys (167 bits)** as a second descriptor to compare. Tanimoto is the standard coefficient for binary fingerprints; Dice is fine too and tends to give slightly higher values for the same overlap — report both if you want to discuss coefficient choice.
- Rank the whole library by similarity to the reference ligand(s). This alone is one screening method you can evaluate (ROC/EF) before touching docking.

**3. Structure-based screening (docking)**
- Retrieve 3CCW (or 1HW8) from RCSB, prepare the receptor (strip waters, add hydrogens/charges — Chimera, PDBFixer, or OpenBabel work fine), define a docking box centered on the co-crystallized ligand (~30×30×30 Å is what the article uses).
- Generate 3D conformers for your active/inactive subsample and dock with AutoDock Vina or Smina, keep only the best pose per molecule.
- This gives you a second independent score per molecule (docking affinity).

**4. Consensus / ML step**
- Simplest version: combine ligand-similarity rank and docking-score rank (e.g., average rank / Borda count, or a simple logistic regression on the two scores).
- More ambitious version (closer to the article): train a classifier (RF or XGBoost) on features derived from the docked poses (or just fingerprint + docking score) to distinguish actives/inactives — this is what they call a target-specific ML scoring function. Given your scope, I'd only do this if you have time left after steps 1–3; it's the most compute/code-heavy part of the article.
- Watch out for the bias the article flags (AVE bias / near-duplicate actives leaking between train and test) — a full AVE-debiasing split is overkill for you, but at least avoid random splits that put near-identical analogs in both train and test; a scaffold-based split is a reasonable middle ground.

**5. Evaluation**
- ROC curve + AUC for each method separately (ligand-based, docking, consensus/ML) — this is your main comparison plot.
- Enrichment factor / normalized EF at top 1% and top 5–10% — more informative than AUC alone for VS, and it's literally the metric the article emphasizes.
- Precision/recall in top-N as a secondary, easy-to-interpret metric.

**Clustering — as a bonus, not a filter.** Don't use clustering to group by "activity closeness" for screening; use it afterward to check chemical diversity of your top hits (e.g., Butina clustering on Morgan fingerprints) — did your best method retrieve diverse scaffolds, or just close analogs of known actives? That's a nice discussion point for the report and matches the "be creative" instruction.

Want me to help you scaffold the actual code (RDKit similarity + Vina docking wrapper + ROC/EF plotting) once you're ready to implement a stage?


To Do:
- [ ] Rapport a rendre le lundi pro (5-8 pages) Editer le rapport ici: [[Uni/Notes/Reports/Chemoinfo_M2 Report/rapportMaster.tex]]
- [ ] In report describe scoring functions
- [ ] Justify the methodology choices
![[Pasted image 20260908151116.png]]


![[Pasted image 20260908154512.png]]https://pubchem.ncbi.nlm.nih.gov/bioassay/339211

- Take active set, select 20-30 as reference. Use the rest as evaluation.
- Rank by max_sim and compute ROC/EF. i.e. the screenening method, using some known actives can find actives that the method has not see yet.

obabel -:"CC(C)C1=C(...)" -O ligand.pdbqt --gen3d -p 7.4 --partialcharge gasteiger


# in PyMOL
print(cmd.centerofmass("resn <ligand_resname>"))  # e.g. resn 4HI

obabel -:"CC(C)C1=C(...)" -O ligand.pdbqt --gen3d -p 7.4 --partialcharge gasteiger


mkdir -p ligands_pdbqt docked

# 1. Convert every molecule in your combined .smi to a separate pdbqt
while read -r smiles id; do
    obabel -:"$smiles" -O "ligands_pdbqt/${id}.pdbqt" --gen3d -p 7.4 --partialcharge gasteiger 2>>errors.log
done < screening_set.smi

# 2. One Vina config, reused for every ligand
cat > config.txt <<EOF
receptor = receptor.pdbqt
center_x = 4.76321
center_y = 31.71096
center_z = 6.64880
size_x = 30
size_y = 30
size_z = 30
exhaustiveness = 8
EOF

# 3. Dock each ligand against the fixed receptor/box
for lig in ligands_pdbqt/*.pdbqt; do
    id=$(basename "$lig" .pdbqt)
    vina --config config.txt --ligand "$lig" \
         --out "docked/${id}_out.pdbqt" --log "docked/${id}.log"
done


import re, glob
records = []
for log in glob.glob("docked/*.log"):
    text = open(log).read()
    m = re.search(r"^\s*1\s+(-?\d+\.\d+)", text, re.M)  # first (best) pose row
    if m:
        records.append({"CHEMBL_ID": log.split("/")[-1].replace(".log",""),
                         "vina_score": float(m.group(1))})
docking_df = pd.DataFrame(records)

mkdir -p ligands_pdbqt docked

# 1. Convert every molecule in your combined .smi to a separate pdbqt
while read -r smiles id; do
    obabel -:"$smiles" -O "ligands_pdbqt/${id}.pdbqt" --gen3d -p 7.4 --partialcharge gasteiger 2>>errors.log
done < screening_set.smi

# 2. One Vina config, reused for every ligand
cat > config.txt <<EOF
receptor = receptor.pdbqt
center_x = <X>
center_y = <Y>
center_z = <Z>
size_x = 24
size_y = 24
size_z = 24
exhaustiveness = 8
EOF

# 3. Dock each ligand against the fixed receptor/box
for lig in ligands_pdbqt/*.pdbqt; do
    id=$(basename "$lig" .pdbqt)
    vina --config config.txt --ligand "$lig" \
         --out "docked/${id}_out.pdbqt" --log "docked/${id}.log"
done



Good questions — let's take them one at a time, because you're conflating two different kinds of "holding out" that actually work differently here.

## Do you need to hold out actives from docking, the way you did for ligand-based?

No — that's a different situation and the reasoning doesn't carry over.

The reason you held out 20 actives as a **reference set** for Tanimoto similarity was specific to nearest-neighbor scoring: a molecule's similarity score is computed *relative to* your set of known actives, so if a molecule is itself in that reference set, it trivially looks maximally similar to itself. That's a leakage mechanism unique to similarity search.

Docking has no such mechanism. Each molecule is docked independently against the fixed receptor — the score for molecule A doesn't depend on whether molecule B is in your set. So it's completely fine (and correct) to dock all 151 actives you selected. No need to further sub-sample them.

## So what do you actually hold out, and when?

The train/test split you need here is the ordinary ML one, applied at the point where you train your combined classifier — not before docking. Concretely:

- You'll end up with **302 molecules that have both scores** (similarity + Vina) — your 151 docked actives + 151 sampled inactives. This is the dataset your consensus/ML model is trained and evaluated on.
- Do a normal stratified train/test split on those 302 (e.g. 70/30, stratified by `Activity` so both classes are proportionally represented in each split), fit your model on train, evaluate ROC/EF on the held-out test portion — same logic as your logistic regression step earlier, just with two features now (`similarity`, `vina_score`) instead of one.

## What about the ~8,173 inactives you never docked?

They simply can't participate in anything that needs a docking score — you don't have one for them, and docking them isn't feasible given your compute budget. Concretely:

- They already contributed to your **ligand-based-only** enrichment/ROC evaluation (the one you did over the full library) — that stands on its own, no docking needed.
- They're excluded from the **structure-based** and **consensus** evaluations, which are necessarily scoped to your 302-molecule docked subset.

This gives you a clean, honest two-tier evaluation to present in the report: "ligand-based screening evaluated on the full 8,475-compound library; structure-based and consensus screening evaluated on a representative 302-compound subsample (all actives + a matched random sample of inactives), due to the computational cost of docking." That's a completely standard and expected caveat in a project like this — nobody will expect you to have docked 8,324 inactives in a computer-room session.

## Can you evaluate docking alone, without the ML model?

Yes, and you should — for the same reason you evaluated ligand-based similarity alone before layering the classifier on top. Rank your 302 docked molecules by Vina score, compute ROC-AUC and enrichment exactly like you did for `similarity`. This gives you your **structure-based baseline**, which you need anyway to answer the question your assignment is actually asking: *does combining the two approaches help?* You can't show that consensus scoring adds value if you don't have the individual-method numbers to compare it against.

## On "I just used Vina, that's standard, where's the creativity?"

This is a common worry, but it's based on a slightly off assumption: the assignment isn't asking you to invent a new docking algorithm — using Vina off-the-shelf is completely normal and expected; that's what essentially every structure-based VS pipeline does, including the one in your professor's article. The creativity your assignment is asking for lives in:

- **The combination itself** — ligand-based + structure-based consensus is explicitly named in your assignment as one of the expected approaches, and it's not a trivial add-on: deciding *how* to combine (simple rank averaging vs. training a classifier on both scores) is a real methodological choice you get to justify.
- **The ML step**, which is exactly the article's core idea: a trained classifier using docking score (+similarity, + potentially other descriptors like number of protein-ligand contacts, or interaction fingerprints if you want to go further) as features tends to outperform the raw docking score alone at distinguishing actives from inactives. Building and evaluating that model — and showing it beats "docking alone" and "similarity alone" — *is* your value-add. You're not asked to write a scoring function from scratch; combining and rescoring intelligently is the accepted meaning of "creative" here.
- **The evaluation design** — comparing methods side by side (ligand-based only vs. docking only vs. consensus) with ROC/EF, and being upfront about the two-tier evaluation scope above, is itself methodologically sound work worth credit.

So: don't worry about Vina being "standard" — the standard tool plus a well-justified combination-and-evaluation strategy is precisely what this kind of project is meant to demonstrate.



Let's fix this piece by piece — there are actually several bugs stacked on top of each other, and the one you're seeing is only the first one Perl trips over.

## The immediate syntax error (line 11)

```perl
@actives_list = ('CHEMBL1496', ..., 'CHEMBL39312')
```
This line is missing its trailing **semicolon**, and under `use strict`, an array variable also needs `my` before it the first time it's used. Because the statement never technically ends, Perl keeps reading forward through the blank line and comment looking for how to finish it, and only gives up when it hits `my @files = glob(...)` on line 11 — hence the confusing "near `) my`" message: it's actually complaining about the boundary between your unfinished list from line 8 and the next declaration.

Fix:
```perl
my @actives_list = ('CHEMBL1496', ..., 'CHEMBL39312');
```
(`my` added, `;` added at the end.)

## Bugs you'll hit next, once that's fixed

**1. `~~` (smartmatch) is deprecated/removed.** In modern Perl (5.38+, which conda-forge's bioconda perl often installs), `~~` no longer exists at all and will throw a syntax error; in slightly older versions it's experimental and throws a warning. Either way it's not something to rely on.

**2. Broken ternary.** `my $is_active = 1 : 0;` is invalid — a ternary needs the condition and the `?`: `cond ? 1 : 0`. As written there's no condition at all.

**3. Scoping bug.** `my $is_active` is declared *inside* the `if` block, so it only exists in that block's scope. In the `else` case (or when the condition is false), `$is_active` was never declared — the later `push ... active => $is_active` outside the block would fail under `strict`.

**4. The real logic bug — filename vs. list entries won't match even once syntax is fixed.** Your docking output files are named like `CHEMBL1496_out.pdbqt` (with the `_out.pdbqt` suffix you added when you ran Vina), but `@actives_list` contains bare IDs like `'CHEMBL1496'`. An exact match between `$filename` and list entries will always be false — you need to strip the suffix first.

**5. Efficiency/style — not a bug, but worth fixing while you're in there.** Testing array membership with smartmatch is O(n) per check; a hash lookup is the idiomatic Perl way and also sidesteps the deprecated operator entirely.

**6. `$total_actives = 150` is hardcoded.** You said you have 151 actives — but if any of your 74 obabel failures came from the actives set, the number you actually docked won't be 150 (or 151). Better to count it directly from the data you parsed rather than hardcode a number that can silently drift out of sync with reality.

## Corrected script

```perl
#!/usr/bin/env perl
use strict;
use warnings;

# --- CONFIGURATION ---
my $pas = 1; # Percentage step for the plot

my @actives_list = ('CHEMBL1496', 'CHEMBL1487', 'CHEMBL54440', /* ...keep your full list here... */ 'CHEMBL39312');

# Hash for O(1) lookup instead of smartmatch
my %actives_hash = map { $_ => 1 } @actives_list;

# Find all docking output files in the current directory
my @files = glob("CHEMBL*_out.pdbqt");

if (!@files) {
    die "Error: No matching CHEMBL*_out.pdbqt files found in this directory.\n";
}

my @extracted_data;

# --- STEP 1: READ ENERGIES AND IDENTIFY ACTIVES ---
foreach my $filename (@files) {
    if (open(my $fh, '<', $filename)) {
        my @lines = <$fh>;
        close($fh);

        next if (scalar(@lines) < 2);

        my $energy = substr($lines[1], 23, 7);
        $energy =~ s/\s+//g;

        # Strip "_out.pdbqt" to get the bare ID for comparison
        (my $id = $filename) =~ s/_out\.pdbqt$//;

        my $is_active = exists $actives_hash{$id} ? 1 : 0;

        push @extracted_data, {
            energy => $energy,
            active => $is_active,
            name   => $filename,
        };
    } else {
        warn "Could not open file '$filename': $!\n";
    }
}

my $total_ligands = scalar(@extracted_data);
my $total_actives = scalar(grep { $_->{active} == 1 } @extracted_data);

print "Successfully read $total_ligands files ($total_actives flagged active).\n";

# --- STEP 2: SORT BY ENERGY (ascending — more negative is better) ---
my @sorted_data = sort { $a->{energy} <=> $b->{energy} } @extracted_data;

# --- STEP 3: CALCULATE ENRICHMENT DATA ---
open(my $out_fh, '>', "enrichissement.dat") or die "Cannot write to enrichissement.dat: $!\n";

for (my $p = $pas; $p <= 100; $p += $pas) {
    my $count_to_check = int(($p / 100) * $total_ligands);
    $count_to_check = 1 if $count_to_check < 1;

    my $actives_found = 0;
    for (my $i = 0; $i < $count_to_check; $i++) {
        $actives_found++ if $sorted_data[$i]->{active} == 1;
    }

    my $perc_bon = ($actives_found / $total_actives) * 100;
    printf $out_fh "%d   %.2f\n", $p, $perc_bon;
}

close($out_fh);
print "Enrichment data written to 'enrichissement.dat'\n";
```

Just paste your full 150-entry list back in where I've abbreviated it — no need to retype it.

One sanity check before you trust the output: `substr($lines[1], 23, 7)` assumes a fixed column position for the energy value in Vina's `REMARK VINA RESULT:` line. Open one `.pdbqt` output and confirm line 2 actually looks like `REMARK VINA RESULT:    -7.6      0.000      0.000` with the number landing in that character range — very negative scores (e.g. `-10.2` vs `-7.6`) can shift column alignment slightly and silently corrupt the parse. Safer (and equally simple) would be a regex instead: `my ($energy) = $lines[1] =~ /RESULT:\s*(-?\d+\.?\d*)/;` — worth swapping in if you want to stop worrying about column counting entirely.

## Is this a valid way to get enrichment data?

Yes, methodologically it's the identical approach to the `get_enrichment_data` function you already have working in your Python notebook — rank by score (here ascending, since more negative Vina energy = better binding), then for each top-p% slice count what fraction of all actives are captured. Same math, different language.

Given that you already have this exact logic debugged in Python, and zero prior Perl experience, you could just as validly skip this script entirely and extend your existing pipeline instead: parse the Vina logs into `docking_df` (as I sketched a few messages back), merge on `CHEMBL_ID` into `molecule_dataset`, and reuse `get_enrichment_data(molecule_dataset, "vina_score", "Activity")` — same output, one fewer toolchain to debug. If your professor specifically wants this Perl script's output format (e.g., for a `gnuplot` step later in the course materials), keep it and use the fixed version above; otherwise, staying in Python is probably less friction for you at this point.