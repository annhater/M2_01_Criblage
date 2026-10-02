mkdir -p smina_results

for lig in ligands_pdbqt/*.pdbqt; do
    id=$(basename "$lig" .pdbqt)
    smina --config config.txt --ligand "$lig" \
         --out "docked/${id}_smina_out.pdbqt" --log "docked/${id}_smina.log"
done

