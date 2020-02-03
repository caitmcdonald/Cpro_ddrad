#!/bin/bash
### This shell script does the following:
### 1. Runs fastqc and multiqc on raw sequencing libraries
### 2. Runs trimmomatic on raw sequencing libraries
### 3. Re-runs fastqc and multiqc on trimmed sequencing libraries

### Edited: 1/26/20

mkdir /workdir/cam435/raw
mkdir /workdir/cam435/trimmed
export RAW=/workdir/cam435/raw
export TRIMMED=/workdir/cam435/trimmed

#FASTQC, RAW LIBS
cd $RAW
mkdir fastqc_raw
fastqc *.fastq.gz -o ./fastqc_raw -t 24 &&

#MULTIQC, RAW LIBS
export LC_ALL=en_US.UTF-8
export PATH=/programs/miniconda3/bin:$PATH
source activate multiqc
multiqc ./fastqc_raw -o ./multiqc_raw &&

#TRIMMOMATIC
cd $RAW
for f in *.fastq.gz; do printf '%s\n' "${f%.fastq.gz}"; done >> sample_ids.txt

cat sample_ids.txt | parallel 'java -jar /programs/trimmomatic/trimmomatic-0.39.jar SE {}.fastq.gz {}.trimmed.fastq.gz ILLUMINACLIP:/programs/trimmomatic/adapters/TruSeq3-SE.fa:2:30:10 SLIDINGWINDOW:4:15 CROP:95 MINLEN:95' &&

#FASTQC, TRIMMED LIBS
cd $TRIMMED
mv $RAW/*trimmed.fastq.gz ./
mkdir fastqc_trimmed
fastqc *.trimmed.fastq.gz -o ./fastqc_trimmed -t 24 &&

#MULTIQC, TRIMMED LIBS
multiqc ./fastqc_trimmed -o ./multiqc_trimmed
