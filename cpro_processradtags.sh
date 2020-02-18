#!/bin/bash

######
# process_radtags: first step of STACKS pipeline

# This shell script does the following:
	# 1. Creates all necessary input and output directories
	# 2. Runs process_radtags in parallel in the background on each barcode-index combination

# Precondition: trimmed RAD sequencing libraries (see cpro_trimmomatic.sh)
######

# Create working directories
mkdir /workdir/cam435/proc_radtags
export RADTAGS=/workdir/cam435/proc_radtags
export TRIMMED=/workdir/cam435/trimmed
cd $RADTAGS

# Create barcode directory and add barcode sequences
# These are the text files (e.g. barcodes5.txt and barcodes6.txt) that list all the barcodes used in a single column
mkdir barcodes
cp /home/cam435/cpro_ddrad/barcodes/barcodes5.txt $RADTAGS/barcodes
cp /home/cam435/cpro_ddrad/barcodes/barcodes6.txt $RADTAGS/barcodes

# Make output directories for each barcode length used
# for C. proseblepon, Steve and Melissa used 5bp and 6bp barcodes
mkdir samples5
mkdir samples6

# Make directories for each library index within each of these barcode directories
# for C. proseblepon, Steve and Melissa used indices 2, 3, 4, 5, 6, 7, & 8
mkdir samples5/i2_CGATGT
mkdir samples5/i3_TTAGGC
mkdir samples5/i4_TGACCA
mkdir samples5/i5_ACAGTG
mkdir samples5/i6_GCCAAT
mkdir samples5/i7_CAGATC
mkdir samples5/i8_ACTTGA

mkdir samples6/i2_CGATGT
mkdir samples6/i3_TTAGGC
mkdir samples6/i4_TGACCA
mkdir samples6/i5_ACAGTG
mkdir samples6/i6_GCCAAT
mkdir samples6/i7_CAGATC
mkdir samples6/i8_ACTTGA


# Run process_radtags
# note: process_radtags must be run on each library separately, can't be looped because it won't accept positional statements
# note: --adapter_1 is the universal Illumina adapter

# Specify library path (to use STACKS 2.3 instead of 1.48)
export LD_LIBRARY_PATH=/usr/local/gcc-7.3.0/lib64:/usr/local/gcc-7.3.0/lib
export PATH=/programs/stacks-2.3d/bin:$PATH

# library 9844_2229_79228_HJFF3BCX2_Cpros_ddRAD_i2_CGATGT_R1.trimmed.fastq.gz
process_radtags -f $TRIMMED/9844_2229_79228_HJFF3BCX2_Cpros_ddRAD_i2_CGATGT_R1.trimmed.fastq.gz \
-o $RADTAGS/samples5/i2_CGATGT/ \
-b $RADTAGS/barcodes/barcodes5.txt \
--renz-1 sbfI --renz-2 mspI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 1 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &

process_radtags -f $TRIMMED/9844_2229_79228_HJFF3BCX2_Cpros_ddRAD_i2_CGATGT_R1.trimmed.fastq.gz \
-o $RADTAGS/samples6/i2_CGATGT/ \
-b $RADTAGS/barcodes/barcodes6.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &


# library 9844_2229_79229_HJFF3BCX2_Cpros_ddRAD_i3_TTAGGC_R1.trimmed.fastq.gz
process_radtags -f $TRIMMED/9844_2229_79229_HJFF3BCX2_Cpros_ddRAD_i3_TTAGGC_R1.trimmed.fastq.gz \
-o $RADTAGS/samples5/i3_TTAGGC/ \
-b $RADTAGS/barcodes/barcodes5.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &

process_radtags -f $TRIMMED/9844_2229_79229_HJFF3BCX2_Cpros_ddRAD_i3_TTAGGC_R1.trimmed.fastq.gz \
-o $RADTAGS/samples6/i3_TTAGGC/ \
-b $RADTAGS/barcodes/barcodes6.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &


# library 9844_2229_79230_HJFF3BCX2_Cpros_ddRAD_i4_TGACCA_R1.trimmed.fastq.gz
process_radtags -f $TRIMMED/9844_2229_79230_HJFF3BCX2_Cpros_ddRAD_i4_TGACCA_R1.trimmed.fastq.gz \
-o $RADTAGS/samples5/i4_TGACCA/ \
-b $RADTAGS/barcodes/barcodes5.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &

process_radtags -f $TRIMMED/9844_2229_79230_HJFF3BCX2_Cpros_ddRAD_i4_TGACCA_R1.trimmed.fastq.gz \
-o $RADTAGS/samples6/i4_TGACCA/ \
-b $RADTAGS/barcodes/barcodes6.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &


# library 9844_2229_79231_HJFF3BCX2_Cpros_ddRAD_i5_ACAGTG_R1.trimmed.fastq.gz
process_radtags -f $TRIMMED/9844_2229_79231_HJFF3BCX2_Cpros_ddRAD_i5_ACAGTG_R1.trimmed.fastq.gz \
-o $RADTAGS/samples5/i5_ACAGTG/ \
-b $RADTAGS/barcodes/barcodes5.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &

process_radtags -f $TRIMMED/9844_2229_79231_HJFF3BCX2_Cpros_ddRAD_i5_ACAGTG_R1.trimmed.fastq.gz \
-o $RADTAGS/samples6/i5_ACAGTG/ \
-b $RADTAGS/barcodes/barcodes6.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &


# library 9844_2229_79232_HJFF3BCX2_Cpros_ddRAD_i6_GCCAAT_R1.trimmed.fastq.gz
process_radtags -f $TRIMMED/9844_2229_79232_HJFF3BCX2_Cpros_ddRAD_i6_GCCAAT_R1.trimmed.fastq.gz \
-o $RADTAGS/samples5/i6_GCCAAT/ \
-b $RADTAGS/barcodes/barcodes5.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &

process_radtags -f $TRIMMED/9844_2229_79232_HJFF3BCX2_Cpros_ddRAD_i6_GCCAAT_R1.trimmed.fastq.gz \
-o $RADTAGS/samples6/i6_GCCAAT/ \
-b $RADTAGS/barcodes/barcodes6.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &


# library 9844_2229_79233_HJFF3BCX2_Cpros_ddRAD_i7_CAGATC_R1.trimmed.fastq.gz
process_radtags -f $TRIMMED/9844_2229_79233_HJFF3BCX2_Cpros_ddRAD_i7_CAGATC_R1.trimmed.fastq.gz \
-o $RADTAGS/samples5/i7_CAGATC/ \
-b $RADTAGS/barcodes/barcodes5.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &

process_radtags -f $TRIMMED/9844_2229_79233_HJFF3BCX2_Cpros_ddRAD_i7_CAGATC_R1.trimmed.fastq.gz \
-o $RADTAGS/samples6/i7_CAGATC/ \
-b $RADTAGS/barcodes/barcodes6.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &


# library 9844_2229_79234_HJFF3BCX2_Cpros_ddRAD_i8_ACTTGA_R1.trimmed.fastq.gz
process_radtags -f $TRIMMED/9844_2229_79234_HJFF3BCX2_Cpros_ddRAD_i8_ACTTGA_R1.trimmed.fastq.gz \
-o $RADTAGS/samples5/i8_ACTTGA/ \
-b $RADTAGS/barcodes/barcodes5.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &

process_radtags -f $TRIMMED/9844_2229_79234_HJFF3BCX2_Cpros_ddRAD_i8_ACTTGA_R1.trimmed.fastq.gz \
-o $RADTAGS/samples6/i8_ACTTGA/ \
-b $RADTAGS/barcodes/barcodes6.txt \
-e sbfI -E phred33 -r -c -q -i gzfastq \
--filter_illumina --barcode_dist_1 2 \
--adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
--adapter_mm 2 &&


# Get read retention information
for f in $RADTAGS/samples5/*;
  do
     [ -d $f ] && cd "$f" && sed -n '3,4p' <process_radtags.trimmed.log
  done | sort -n - | uniq - | { echo "samples5"; cat -; } > radtag_stats_samples5.txt;

for f in $RADTAGS/samples6/*;
  do
     [ -d $f ] && cd "$f" && sed -n '3,4p' <process_radtags.trimmed.log
  done | sort -n - | uniq - | { echo "samples6"; cat -; } > radtag_stats_samples6.txt;

paste radtag_stats_samples5.txt radtag_stats_samples6.txt > radtag_stats.txt
