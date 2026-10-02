#!/usr/bin/env perl
use strict;
use warnings;

# --- CONFIGURATION ---
my $pas = 1; # Percentage step for the plot

my @actives_list = ('CHEMBL1496', 'CHEMBL1487', 'CHEMBL54440', 'CHEMBL1144', 'CHEMBL169046', 'CHEMBL1477', 'CHEMBL1161644', 'CHEMBL2220442', 'CHEMBL2367472', 'CHEMBL2367477', 'CHEMBL1163804', 'CHEMBL64962', 'CHEMBL65037', 'CHEMBL99838', 'CHEMBL100165', 'CHEMBL101497', 'CHEMBL102168', 'CHEMBL151437', 'CHEMBL156695', 'CHEMBL159103', 'CHEMBL159951', 'CHEMBL160102', 'CHEMBL161829', 'CHEMBL162642', 'CHEMBL163277', 'CHEMBL175236', 'CHEMBL177545', 'CHEMBL228528', 'CHEMBL228583', 'CHEMBL228667', 'CHEMBL228954', 'CHEMBL228955', 'CHEMBL249273', 'CHEMBL249724', 'CHEMBL249884', 'CHEMBL249906', 'CHEMBL250088', 'CHEMBL250090', 'CHEMBL250317', 'CHEMBL250500', 'CHEMBL250707', 'CHEMBL250749', 'CHEMBL250953', 'CHEMBL251499', 'CHEMBL303515', 'CHEMBL318707', 'CHEMBL321768', 'CHEMBL329307', 'CHEMBL333443', 'CHEMBL333760', 'CHEMBL345375', 'CHEMBL348798', 'CHEMBL387514', 'CHEMBL389002', 'CHEMBL389216', 'CHEMBL389217', 'CHEMBL389441', 'CHEMBL389442', 'CHEMBL389443', 'CHEMBL391002', 'CHEMBL394937', 'CHEMBL398239', 'CHEMBL398240', 'CHEMBL398551', 'CHEMBL399313', 'CHEMBL399315', 'CHEMBL399360', 'CHEMBL399771', 'CHEMBL399773', 'CHEMBL400560', 'CHEMBL400747', 'CHEMBL400874', 'CHEMBL400973', 'CHEMBL401293', 'CHEMBL403127', 'CHEMBL437774', 'CHEMBL438662', 'CHEMBL438694', 'CHEMBL487720', 'CHEMBL489540', 'CHEMBL1161639', 'CHEMBL1161640', 'CHEMBL1161641', 'CHEMBL1161642', 'CHEMBL1161645', 'CHEMBL1161646', 'CHEMBL1161647', 'CHEMBL1161648', 'CHEMBL1161649', 'CHEMBL1161650', 'CHEMBL1161651', 'CHEMBL1161652', 'CHEMBL1161653', 'CHEMBL1161654', 'CHEMBL1161655', 'CHEMBL1161656', 'CHEMBL1161657', 'CHEMBL1161658', 'CHEMBL1161659', 'CHEMBL1161660', 'CHEMBL1161661', 'CHEMBL1161662', 'CHEMBL1161663', 'CHEMBL1161664', 'CHEMBL1161665', 'CHEMBL1163149', 'CHEMBL1163150', 'CHEMBL1163723', 'CHEMBL1165024', 'CHEMBL1165099', 'CHEMBL2111268', 'CHEMBL2367470', 'CHEMBL2367471', 'CHEMBL2367475', 'CHEMBL2367478', 'CHEMBL2368185', 'CHEMBL2368188', 'CHEMBL2368189', 'CHEMBL2368190', 'CHEMBL2368191', 'CHEMBL2368194', 'CHEMBL2368197', 'CHEMBL2368198', 'CHEMBL2368199', 'CHEMBL2368200', 'CHEMBL2368202', 'CHEMBL2368205', 'CHEMBL2375155', 'CHEMBL2375156', 'CHEMBL3318042', 'CHEMBL3349544', 'CHEMBL3349824', 'CHEMBL3349825', 'CHEMBL3349827', 'CHEMBL3349828', 'CHEMBL3677707', 'CHEMBL3677708', 'CHEMBL3677709', 'CHEMBL3684074', 'CHEMBL3704922', 'CHEMBL3704923', 'CHEMBL3896765', 'CHEMBL3906659', 'CHEMBL3963593', 'CHEMBL3970138', 'CHEMBL3971241', 'CHEMBL3971439', 'CHEMBL3985556', 'CHEMBL4088701', 'CHEMBL39102', 'CHEMBL39312');

my %actives_hash = map { $_ => 1 } @actives_list;

# Find all docking output files in the current directory
my @files = glob("{CHEMBL,DECOY}*_out.pdbqt");

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

for (my $count_to_check = 1; $count_to_check <= $total_ligands; $count_to_check++) {
    my $actives_found = 0;
    for (my $i = 0; $i < $count_to_check; $i++) {
        $actives_found++ if $sorted_data[$i]->{active} == 1;
    }
    my $frac_tested = $count_to_check / $total_ligands;
    my $perc_bon    = ($actives_found / $total_actives) * 100;
    printf $out_fh "%.6f   %.2f\n", $frac_tested, $perc_bon;
}

close($out_fh);
print "Enrichment data written to 'enrichissement.dat'\n";

#add energy data to new output file with molecule names
open(my $energy_fh, '>', "energy_data.dat") or die "Cannot write to energy_data.dat: $!\n";
print $energy_fh "Energy\tName\n";
foreach my $data (@sorted_data) {
    printf $energy_fh "%.6f\t%s\n", $data->{energy}, $data->{name};
}
close($energy_fh);
print "Energy data written to 'energy_data.dat'\n";