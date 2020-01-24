# ddRAD analysis pipeline using STACKS 2.3

###### \*Pipeline adapted from ongoing projects in the Zamudio lab\*

### Pipeline overview
1. [Obtaining sequencing data](#1.-obtaining-sequencing-data)
1. Library QC
1. Quality filtering pre-STACKS (optional)
1. Read demultiplexing (process_radtags)
1. STACKS parameter optimization (optional)
1. Running STACKS
1. Post-STACKS analyses

###### Note 1: this pipeline assumes that you are familiar with bash, SLURM, and are working on the Cornell BioHPC cluster. See these pages for some basics on command line, SLURM, and interacting with the Cornell compute cluster.

###### Note 2: you can implement this pipeline simply through the included code fragments. However, a more efficient approach is to use the scripts included. The script associated with each step is noted.

### 1. Obtaining sequencing data
__1a. Download files:__ You should get an email from the sequencing facility that includes a shell script. Use this script to download libraries to the directory of your choice. Generally, this will be your CBSU home directory. From within your directory:

    nohup sh download.sh &

__1b. Create protected copy of raw libraries:__ it's a good idea to create a protected copy of your data, just so you don't accidentally move it or modify it.

*Script version: ___________.sh*

### 2. Quality control
__2a. Fastqc:__ The easiest way to assess the quality of your libraries is by using fastQC, which provides an .html output of pertinent quality metrics for each library.

__2b. Multiqc:__ Assessing quality for each library individually can be cumbersome if you have a lot of them. Multiqc compiles fastqc results into a single .html output! This is a great way to compare quality across your libraries and look for any weird outliers.

### 3. Quality filtering pre-STACKS (optional)
__3a. Quality filtering:__ If, in looking at multiqc/fastqc, you see libraries that are concerning (e.g. if your per-base sequence quality is low), you may want to pre-filter before running STACKS. The STACKS quality filter parameter is fairly relaxed: it creates a sliding window 15% of the read length, and drops a read if its average quality score within the window drops below 10.

If you decide you need a higher quality score, use a read trimmer like [fastx](http://hannonlab.cshl.edu/fastx_toolkit/commandline.html) to filter according to your requirements. For example, the following command filters out a read if the raw phred score drops below 30 in >50% of the read length and returns a zipped version of the filtered library.

    fastq_quality_filter -q 30 -p 50 -Q33 -z -i <raw_lib> -o <filtered_lib>

Note: fastq_quality_filter is pretty slow and not multi-threaded, so you may want to set up multiple runs in the background in parallel.

__3b. Re-run fastqc and multiqc:__ Once you've finished filtering your raw libraries, run fastqc and multiqc again on the filtered libraries. You should see an improvement in per-base quality scores, etc.

### 4. Process radtags and sample demultiplexing
__4a. Process radtags:__ process_radtags ​is​ ​the​ ​first​ ​step​ ​in​ ​the​ STACKS ​pipeline​. It ​separate​s ​the​ ​reads​ ​based​ ​on​ ​the barcode/index​ ​combination​ ​(which corresponds ​to​ ​one​ ​individual).​ We sequence ​single-end​ ​reads. Illumina​ ​separates​ ​the​ ​reads​ ​based​ ​on​ ​their​ ​indexes,​ ​which​ ​is​ ​on​ ​the​ ​3’​ ​end​ ​of​ ​the​ ​read​ ​(adjacent to​ ​the​ ​second​ ​cut​ ​site).​ ​Within​ ​each​ ​of​ ​these​ ​index-separated​ ​files,​ ​there​ ​are​ ​several​ ​samples each​ ​indexed​ ​with​ ​a​ ​barcode.​ ​In​ ​the​ ​sequencing​ ​process,​ ​the​ ​barcode​ ​is​ ​sequenced​ ​and​ ​the​ ​sbfI cut​ ​site​ ​is​ ​adjacent​ ​to​ ​the​ ​barcode.​ process_radtags ​looks​ ​for​ ​the​ ​barcode​ ​sequences​ ​we​ ​tell​ ​it​ ​to look​ ​for,​ ​and​ ​also​ ​checks​ ​to​ ​make​ ​sure​ ​that​ ​the​ ​sbfI​ ​cut​ ​site​ ​is​ ​adjacent.​ ​

You​ ​will​ ​also​ ​have​ ​to​ ​create​ ​a​ ​folder​ ​called​ ​barcodes,​ ​which​ will​ ​contain​ ​the​ ​files​ ​barcodes5.txt, barcodes6.txt,​ ​and​ ​barcodes7.txt.​ ​These​ ​files​ ​will​ ​contain​ ​the​ ​barcode​ ​sequences​ ​you​ ​used​ ​in your​ ​sequencing​ ​run,​ ​separated​ ​by​ ​length. For example:

    #​barcodes5.txt
    AGCCC
    GTATT
    CTGTA
    AGCAT
    ACTAT

You​ ​will​ ​also have​ ​to​ ​build the​ ​directories​ ​for​ process_radtags ​based​ ​on​ ​the​ ​barcodes​ ​and​ ​indexes​ ​you​ ​used. process_radtags ​runs​ ​best​ ​when​ ​you​ ​separate​ ​the​ ​barcodes​ ​by​ ​length.​ ​Generally,​ ​you​ ​will​ ​have barcodes​ ​that​ ​are​ ​5bp,​ ​6bp,​ ​and/or​ ​7bp​ ​in​ ​length.​ ​So ​you​ ​should​ ​make​ ​directories​ ​called samples5,​ ​samples6,​ ​and​ ​samples7.​ ​The​ ​samples​ ​that​ ​were​ ​indexed​ ​with​ ​the​ ​5​​bp​ ​barcode​ ​will be​ ​put​ ​in​ ​the​ ​samples5​ ​folder.​ ​Within​ ​each​ ​samplesX​ ​folder,​ ​you​ ​also need​ ​to​ ​make​ ​directories​ ​for​ ​all the​ ​indexes​ ​that​ ​you​ ​used​ ​(actually​ ​the​ ​reverse​ ​complement​ ​of​ ​the​ ​index​ ​because​ ​of​ ​the​ ​way​ ​it​ ​is sequenced).

This sounds confusing! Look at the process_radtags.sh script for clarification.

Once you have all directories created, you can run process_radtags. A typical run looks like this:

    process_radtags -f ./raw/9844_2229_79228_HJFF3BCX2_Cpros_ddRAD_i2_CGATGT_R1.fastq.gz \
    -o ./samples5/i2_CGATGT/ \
    -b ./barcodes/barcodes5.txt \
    --renz-1 sbfI --renz-2 mspI -E phred33 -r -c -q -i gzfastq \
    --filter_illumina --barcode_dist_1 1 \
    --adapter_1 AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT \
    --adapter_mm 2 &

Note: process_radtags doesn't have built-in parallelization, and it also cannot be looped because it doesn't accept positional statements. If you have a lot of libraries, the most efficient way to run it is to execute it in the background (write a shell script that executes the program process_radtags for each library/barcode combination. Make sure that each program is followed by & as above, otherwise it won't be executed in the background!).

Once process_radtags is finished, you need to check your read retention. You can generate a file with library stats for each barcode length including \#reads retained, \#flagged by illumina, etc., like so:

    for f in /workdir/cam435/samples5/*; do [ -d $f ] && cd "$f" && sed -n '3,4p' <process_radtags.raw.log; done | sort -n - |uniq - | { echo "samples5"; cat -; } > process_radtag_stats_samples5.txt

From here, you can easily determine the % of reads retained for each library by summing \#reads retained for each barcode length, then dividing by \#total reads. Following process_radtags, >70% of your raw reads should be retained.

Lower read retention may indicate library prep or sequencing errors, in which case you should troubleshoot. To improve read retention, you can follow the pre-filtering steps in \#3. You can also relax some process_radtag parameters, such as --adapter_mismatch and --barcode_dist_1. If this does not improve read retention, you can --disable_rad_check. This isn't ideal because reads without intact RAD sites will be retained, but it may be your only option.

__4b. Renaming samples:__


You can check your sample read numbers like so:

for file in *.fq; do echo -n $(basename $file .fq)$'\t'; cat $file | grep '^@' | wc -l; done | { echo "individual    raw_reads"; cat -; } > sample_readcounts.txt


### 6. Post-STACKS analyses
__6a. Quantify missing data:__ the amount of missing data you tolerate will vary based on your organism, sampling, and sequencing approaches. One number I've heard thrown around is to omit individuals (and variants) with >50% missing data. Another approach is to look for outliers, or individuals with a lot more missing data than all other individuals. However, many people find that omitting individuals with high missing data has no impact on their results, so it may not be necessary at all. One benefit is that it removing uninformative individuals and variants will reduce your file size and speed subsequent analyses. If you want to omit individuals with high missing data, you have a couple options:

__a) Remove them from your pertinent populations output files before continuing with downstream analyses.__

__b) Remove them and re-run the entire STACKS pipeline.__ If you have individuals with lots of missing data, in theory this could affect how STACKS builds loci. If it's computationally feasible (i.e. you don't have a ton of libraries, so your runtime is reasonable), you might want to remove samples with high missing data and re-run STACKS again.

You can use VCFtools to check missing data for each individual:

    vcftools --vcf <yourdata>.vcf --missing-indv --out <yourdata>

From here, you can exclude individuals with a lot of missing data, and exclude variants above a missingness threshold:

    vcftools --vcf <data>.vcf --remove-indv <inds> --max-missing 0.5 --recode --recode-INFO-all --out <data.noind.miss0.5> --stdout

__6b. PCA:__ a good first step to explore your data is to generate a PCA.
