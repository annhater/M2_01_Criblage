mkdir -p ligands_pdbqt
OBABEL="$(conda info --base)/envs/bioinfo/bin/obabel"

# 1. Convert every molecule in your combined .smi to a separate pdbqt
while read -r smiles id; do
    "$OBABEL" -:"$smiles" -O "ligands_pdbqt/${id}.pdbqt" --gen3d -p 7.4 --partialcharge gasteiger 2>>errors.log
done < ligands_no_salts.smi

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

done