for lig in ligands_pdbqt/*.pdbqt; do
    id=$(basename "$lig" .pdbqt)
    vina --config config.txt --ligand "$lig" \
         --out "docked/${id}_out.pdbqt" --log "docked/${id}.log"
done