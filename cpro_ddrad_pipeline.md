# ddRAD analysis pipeline using STACKS 2.3

###### \*Pipeline adapted from ongoing projects in the Zamudio lab\*

### Pipeline overview
1. [Obtaining sequencing data](#obtaining-sequencing-data)
1. [Library QC](#quality-control)
1. [Quality filtering pre-STACKS (optional)](#quality-filtering-pre-stacks-(optional))
1. [Read demultiplexing (process_radtags)](#process-radtags-and-sample-demultiplexing)
1. STACKS parameter optimization (optional)
1. Running STACKS
1. [Post-STACKS analyses](#post-stacks-analyses)

###### Note 1: this pipeline assumes that you are familiar with bash, SLURM, and are working on the Cornell BioHPC cluster. See these pages for some basics on command line, SLURM, and interacting with the Cornell compute cluster.

###### Note 2: you can implement this pipeline simply through the included code fragments. However, a more efficient approach is to use the scripts included. The script associated with each step is noted.

### Obtaining sequencing data
__1a. Download files:__ You should get an email from the sequencing facility that includes a shell script. Use this script to download libraries to the directory of your choice. Generally, this will be your CBSU home directory. From within your home directory:

    mkdir <project_name>
    cd <project_name>
    nohup sh download.sh &

__1b. Create protected copy of raw libraries:__ it's a good idea to create a protected copy of your data, just so you don't accidentally move it or modify it. Chattr is a command line utility that will make files and directories immutable so they can't be deleted/modified:

    mkdir rawreads_protected
    cp /path/to/rawreads ./rawreads_protected
    sudo chattr -R +i rawreads_protected

Where -R +i makes all the files in a directory immutable recursively. If you want to delete or modify the files in the future, you can remove the immutable attribute at any time using -i instead.

\*NOTE: you do not have chattr privileges on CBSU machines, so this will only work if you save protected reads on a different machine. If you want to protect files in your CBSU home directory, try:

    chmod 444 <file>

This changes the file permissions to read-only for all users. If you (as the file owner) try to modify, you will receive a message asking you to confirm your action before any modification is actually made.

*Script version: ___________.sh*

### Quality control
__2a. Fastqc:__ The easiest way to assess the quality of your libraries is by using fastQC, which provides an .html output of pertinent quality metrics for each library.

__2b. Multiqc:__ Assessing quality for each library individually can be cumbersome if you have a lot of them. Multiqc compiles fastqc results into a single .html output! This is a great way to compare quality across your libraries and look for any weird outliers.

### Quality filtering pre-STACKS (optional)
__3a. Quality filtering:__ If, in looking at multiqc/fastqc, you see libraries that are concerning (e.g. if your per-base sequence quality is low or you have adapter content), you may want to pre-filter before running STACKS. The STACKS quality filter parameter is very relaxed: it creates a sliding window 15% of the read length and drops a read if its average quality score within the window falls below 10. It also does NOT remove adapter contamination effectively, so if you have any adapter read-through, you'll need to remove adapter contamination BEFORE running STACKS.

If you need to do pre-filtering, Trimmomatic is a good option:

    java -jar /programs/trimmomatic/trimmomatic-0.39.jar SE -phred33 -threads 23 inputreads.fq outputreads.fq ILLUMINACLIP:/programs/trimmomatic/adapters/TruSeq3-SE.fa:2:30:10 SLIDINGWINDOW:4:10 CROP:95 MINLEN:95

Note that Trimmomatic processing steps are done sequentially, so order of the above command matters (i.e. first adapter contamination is removed, then sliding window quality is performed, then reads are cropped and only reads of 95bp are retained).

__3b. Re-run fastqc and multiqc:__ Once you've finished filtering your raw libraries, run fastqc and multiqc again on the filtered libraries. You should see an improvement in per-base quality scores, adapter contamination, etc.

### Process radtags and sample demultiplexing
__4a. Process radtags:__ process_radtags ​is​ ​the​ ​first​ ​step​ ​in​ ​the​ STACKS ​pipeline​. It ​separate​s ​the​ ​reads​ ​based​ ​on​  barcode/index​ ​combination​ ​(which corresponds ​to​ a single ​individual).​ We sequence typically sequence ​single-end​ ​reads. Illumina​ ​separates​ ​the​ ​reads​ ​based​ ​on​ ​their​ ​indexes,​ ​which​ are ​on​ ​the​ ​3’​ ​end​ ​​(adjacent to​ ​the​ ​second​ ​cut​ ​site).​ ​Within​ ​each​ ​of​ ​these​ ​index-separated​ ​files,​ ​there​ ​are​ ​several​ ​samples each​ ​indexed​ ​with​ ​a​ ​barcode.​ ​In​ ​the​ ​sequencing​ ​process,​ ​the​ ​barcode​ ​is​ ​sequenced​ ​and​ ​the​ ​sbfI cut​ ​site​ ​is​ ​adjacent​ ​to​ ​the​ ​barcode.​ process_radtags ​looks​ ​for​ ​the​ ​barcode​ ​sequences​ ​we​ ​tell​ ​it​ ​to look​ ​for,​ ​and​ ​also​ ​checks​ ​to​ ​make​ ​sure​ ​that​ ​the​ ​sbfI​ ​cut​ ​site​ ​is​ ​adjacent.​ ​

Generally,​ ​you​ ​will​ ​have used barcodes​ ​that​ ​are​ ​5bp,​ ​6bp,​ ​and/or​ ​7bp​ ​in​ ​length during library prep. process_radtags ​runs​ ​best​ ​when​ ​you​ ​separate​ ​the​ ​barcodes​ ​by​ ​length.​ ​To demultiplex libraries with process_radtags, first create​ ​a​ directory ​called​ ​barcodes,​ ​which​ will​ ​contain​ ​the​ ​files​ ​with all barcodes of each length (e.g. barcodes5.txt, barcodes6.txt).​ ​These​ ​files​ ​will​ ​contain​ ​all the​ ​barcode​ ​sequences​ ​you​ ​used​ ​in your​ ​sequencing​ ​run,​ ​separated​ ​by​ ​length. For example:

    #​barcodes5.txt
    AGCCC
    GTATT
    CTGTA
    AGCAT
    ACTAT

Next create ​the output directories​ ​for​ process_radtags. These are based​ ​on​ ​the​ ​barcodes​ ​and​ ​indexes​ ​you​ ​used.​ ​So ​for example you​ ​should​ ​make​ ​directories​ ​called samples5,​ ​samples6,​ ​and​ ​samples7.​ Within​ ​each​ ​samplesX​ ​folder,​ ​you​ ​also need​ ​to​ ​make​ ​directories​ ​for​ ​all the​ ​indexes​ ​that​ ​you​ ​used​. Once finished, process_radtags will put the samples that were indexed with the Xbp barcode and iX index into the appropriate folder (e.g. 5bp barcode + i2 in directory samples5/index2CGATGT).​

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

__4b. Check read retention:__
Once process_radtags is finished, you need to check your read retention. You can generate a file with library stats for each barcode length including \#reads retained, \#flagged by illumina, etc., like so:

    for f in /workdir/cam435/samples5/*; do [ -d $f ] && cd "$f" && sed -n '3,4p' <process_radtags.raw.log; done | sort -n - |uniq - | { echo "samples5"; cat -; } > process_radtag_stats_samples5.txt*

From here, you can easily determine the % of reads retained for each library by summing \#reads retained for each barcode length, then dividing by \#total reads. Following process_radtags, >70% of your raw reads should be retained.

Lower read retention may indicate library prep or sequencing errors, in which case you should troubleshoot. To improve read retention, you can follow the pre-filtering steps in \#3. You can also relax some process_radtag parameters, such as --adapter_mismatch and --barcode_dist_1. If this does not improve read retention, you can --disable_rad_check. This isn't ideal because reads without intact RAD sites will be retained, but it may be your only option.

__4b. Renaming samples:__
After your samples have been demultiplexed, rename them according to sample ID. It's easiest to do this by writing a bunch of mv commands based on your sample metadata in excel. See​ ​the​ ​file called​ ​sample_rename_commands.xlsx​ ​to​ ​see​ ​how​ ​to​ ​make​ ​the​ ​mv​ commands​ ​to rename​ ​the​ ​files. You can paste these mv commands directly into the shell, no need to put them in a script.

Note:​ ​if​ ​you​ ​have​ ​technical​ ​replicates​ ​of​ ​your​ ​samples​ ​(the​ ​same​ ​sample​ ​ID​ ​included​ ​in​ ​multiple libraries​) you​ ​should​ ​manually​ ​rename​ ​them​ ​at​ ​this​ ​stage.​ ​For​ ​example,​ if ​you​ ​have​ ​the sample​ ​called​ ​TC95​ ​in​ both ​Library1​ ​and​ ​Library2, ​when​ you ​run ​Stacks,​ ​one​ ​of these​ ​files​ ​will​ ​be​ ​over-written​. To prevent this, ​rename​ them, e.g. TC95_1.fastq and TC95_2.fastq.​

You can check your sample read numbers like so:

for file in *.fq; do echo -n $(basename $file .fq)$'\t'; cat $file | grep '^@' | wc -l; done | { echo "individual    raw_reads"; cat -; } > sample_readcounts.txt*

### STACKS parameter optimization
__5a. Testing STACKS parameters:__ Default STACKS parameters may not be optimal

__5b. Choosing optimal parameters: __


### Post-STACKS analyses
__6a. Quantify missing data:__ the amount of missing data you tolerate will vary based on your organism, sampling, and sequencing approaches. One number I've heard thrown around is to omit individuals (and variants) with >50% missing data. Another approach is to look for outliers, or individuals with a lot more missing data than all other individuals. However, many people find that omitting individuals with high missing data has no impact on their results, so it may not be necessary at all. One benefit is that it removing uninformative individuals and variants will reduce your file size and speed subsequent analyses. If you want to omit individuals with high missing data, you have a couple options:

__a) Remove them from your pertinent populations output files before continuing with downstream analyses.__

__b) Remove them and re-run the entire STACKS pipeline.__ If you have individuals with lots of missing data, in theory this could affect how STACKS builds loci. If it's computationally feasible (i.e. you don't have a ton of libraries, so your runtime is reasonable), you might want to remove samples with high missing data and re-run STACKS again.

You can use VCFtools to check missing data for each individual:

    vcftools --vcf populations.snps.vcf --missing-indv --out <output_prefix>

From here, you can exclude individuals with a lot of missing data, and exclude variants above a missingness threshold:

    vcftools --vcf <data>.vcf --remove-indv <inds> --max-missing 0.5 --recode --recode-INFO-all --out <data.noind.miss0.5> --stdout

__6b. PCA:__ a good first step to explore your data is to generate a PCA.
