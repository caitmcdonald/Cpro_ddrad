#!/bin/bash

######

# Extract distribution of SNPs from Stacks populations.log.distribs files for parameter testing

# These SNP distributions are necessary for plotting 1) number of total loci, 2) number of polymorphic loci, 3) number of SNPs, and 4) number of SNPs per locus. All of these plots are helpful for determining optimal parameter values of -m, -M, and -n (see cpro_stacks_params_compare.R)

# These commands can be run from within the directory containing all the Stacks denovomap output directories.

# Precondition: denovomap.pl has been run on a set of test samples, with varying values for -m, M, and -n (see e.g. cpro_denovo_slurm_M5n5.sh)

######

#Testing M1n1-M9n9
for i in 1 2 3 4 5 6 7 8 9 
do
awk '/snps_per_loc_postfilters/{flag=1; next} /END/{flag=0} flag' stacks_M${i}n${i}/populations.log.distribs > M${i}n${i}.tsv
done