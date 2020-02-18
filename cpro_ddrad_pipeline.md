# ddRAD analysis pipeline using Stacks 2.3

###### \*Pipeline adapted from ongoing projects in the Zamudio lab\*

### Pipeline overview
1. [Obtaining sequencing data](#step-1-obtaining-sequencing-data)
1. [Library QC](#step-2-quality-control)
1. [Quality filtering pre-Stacks (optional)](#step-3-quality-filtering-pre-stacks)
1. [Read demultiplexing (process_radtags)](#step-4-process-radtags-and-sample-demultiplexing)
1. [Stacks parameter optimization (optional)](#step-5-Stacks-parameter-optimization)
1. [Running Stacks](#step-6-run-stacks-on-full-dataset)
1. [Post-Stacks SNP filtering](#step-7-post-stacks-snp-filtering)

##### Note 1: This pipeline assumes that you are familiar with bash, SLURM, and are working on the Cornell BioHPC cluster. See these pages for some basics on command line, SLURM, and interacting with the Cornell compute cluster.

##### Note 2: There are lots of resources beyond this pipeline for running Stacks. Some good options are:
- [The online Stacks manual.](http://catchenlab.life.illinois.edu/stacks/) This will be your most up-to-date option.
- [This published sample pipeline](https://www.nature.com/articles/nprot.2017.123). This is really detailed and good if you have little command line experience. Note that this pipeline has steps that are specific to Stacks v1.4 that have since been deprecated for Stacks v2.3.
- [The dDocent filtering tutorial](https://www.ddocent.com/filtering/). This is a nice intro into using VCFtools for SNP quality filtering.
- [This paper with suggested SNP filtering thresholds](https://onlinelibrary.wiley.com/doi/full/10.1111/mec.14792). This provides a comprehensive comparison of and justification for different SNP filtering approaches.

### Step 1. Obtaining sequencing data
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

### Step 2. Quality control
__2a. Fastqc:__ The easiest way to assess the quality of your libraries is by using fastQC, which provides an .html output of pertinent quality metrics for each library.

__2b. Multiqc:__ Assessing quality for each library individually can be cumbersome if you have a lot of them. Multiqc compiles fastqc results into a single .html output! This is a great way to compare quality across your libraries and look for any weird outliers.

### Step 3. Quality filtering pre-Stacks
__3a. Quality filtering:__ If, in looking at multiqc/fastqc, you see libraries that are concerning (e.g. if your per-base sequence quality is low or you have adapter content), you may want to pre-filter before running Stacks. The Stacks quality filter parameter is very relaxed: it creates a sliding window 15% of the read length and drops a read if its average quality score within the window falls below 10. It also does NOT remove adapter contamination effectively, so if you have any adapter read-through, you'll need to remove adapter contamination BEFORE running Stacks.

If you need to do pre-filtering, Trimmomatic is a good option:

    java -jar /programs/trimmomatic/trimmomatic-0.39.jar SE -phred33 -threads 23 inputreads.fq outputreads.fq ILLUMINACLIP:/programs/trimmomatic/adapters/TruSeq3-SE.fa:2:30:10 SLIDINGWINDOW:4:10 CROP:95 MINLEN:95

Note that Trimmomatic processing steps are done sequentially, so order of the above command matters (i.e. first adapter contamination is removed, then sliding window quality is performed, then reads are cropped and only reads of 95bp are retained).

__3b. Re-run fastqc and multiqc:__ Once you've finished filtering your raw libraries, run fastqc and multiqc again on the filtered libraries. You should see an improvement in per-base quality scores, adapter contamination, etc.

*See sample trimming* [***script***](cpro_trimmomatic.sh)

### Step 4. Process radtags and sample demultiplexing
__4a. Process radtags:__ process_radtags ​is​ ​the​ ​first​ ​step​ ​in​ ​the​ Stacks ​pipeline​. It ​separate​s ​the​ ​reads​ ​based​ ​on​  barcode/index​ ​combination​ ​(which corresponds ​to​ a single ​individual).​ We sequence typically sequence ​single-end​ ​reads. Illumina​ ​separates​ ​the​ ​reads​ ​based​ ​on​ ​their​ ​indexes,​ ​which​ are ​on​ ​the​ ​3’​ ​end​ ​​(adjacent to​ ​the​ ​second​ ​cut​ ​site).​ ​Within​ ​each​ ​of​ ​these​ ​index-separated​ ​files,​ ​there​ ​are​ ​several​ ​samples each​ ​indexed​ ​with​ ​a​ ​barcode.​ ​In​ ​the​ ​sequencing​ ​process,​ ​the​ ​barcode​ ​is​ ​sequenced​ ​and​ ​the​ ​sbfI cut​ ​site​ ​is​ ​adjacent​ ​to​ ​the​ ​barcode.​ process_radtags ​looks​ ​for​ ​the​ ​barcode​ ​sequences​ ​we​ ​tell​ ​it​ ​to look​ ​for,​ ​and​ ​also​ ​checks​ ​to​ ​make​ ​sure​ ​that​ ​the​ ​sbfI​ ​cut​ ​site​ ​is​ ​adjacent.​ ​

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

*See sample process_radtags* [***script***](cpro_processradtags.sh)

__4b. Check read retention:__
Once process_radtags is finished, you need to check your read retention. You can generate a file with library stats for each barcode length including \#reads retained, \#flagged by illumina, etc., like so:

    for f in /workdir/cam435/samples5/*; do [ -d $f ] && cd "$f" && sed -n '3,4p' <process_radtags.raw.log; done | sort -n - |uniq - | { echo "samples5"; cat -; } > process_radtag_stats_samples5.txt*

From here, you can easily determine the % of reads retained for each library by summing \#reads retained for each barcode length, then dividing by \#total reads. Following process_radtags, >70% of your raw reads should be retained.

Lower read retention may indicate library prep or sequencing errors, in which case you should troubleshoot. To improve read retention, you can follow the pre-filtering steps in \#3. You can also relax some process_radtag parameters, such as --adapter_mismatch and --barcode_dist_1. If this does not improve read retention, you can --disable_rad_check. This isn't ideal because reads without intact RAD sites will be retained, but it may be your only option.

__4b. Renaming samples:__
After your samples have been demultiplexed, rename them according to sample ID. It's easiest to do this by writing a bunch of mv commands based on your sample metadata in excel. See​ ​the​ ​file called​ ​sample_rename_commands.xlsx​ ​to​ ​see​ ​how​ ​to​ ​make​ ​the​ ​mv​ commands​ ​to rename​ ​the​ ​files. You can paste these mv commands directly into the shell, no need to put them in a script.

*See sample move commands* [***.xlsx***](cpro_sample_rename_mv.xlsx)

Note:​ ​if​ ​you​ ​have​ ​technical​ ​replicates​ ​of​ ​your​ ​samples​ ​(the​ ​same​ ​sample​ ​ID​ ​included​ ​in​ ​multiple libraries​) you​ ​should​ ​manually​ ​rename​ ​them​ ​at​ ​this​ ​stage.​ ​For​ ​example,​ if ​you​ ​have​ ​the sample​ ​called​ ​TC95​ ​in​ both ​Library1​ ​and​ ​Library2, ​when​ you ​run ​Stacks,​ ​one​ ​of these​ ​files​ ​will​ ​be​ ​over-written​. To prevent this, ​rename​ them, e.g. TC95_1.fastq and TC95_2.fastq.​

After renaming your files, you can check your sample read numbers like so:

    for file in *.fq; do echo -n $(basename $file .fq)$'\t'; cat $file | grep '^@' | wc -l; done | { echo "individual    raw_reads"; cat -; } > sample_readcounts.txt*

__4c. Create a population map:__
Once your samples are renamed, create a population map. This tab-delimited file will tell Stacks to which populations your samples belong. This file should contain one column for sample names, one column for the population of origin, and no headers, like so:

    sample1    population1
    sample2    population1
    sample3    population2

### Step 5. Stacks parameter optimization
Default Stacks parameters are unlikely to be optimal because the efficacy of different parameter values will depend on the quality and composition of your sequencing data. So, you should always test a series of parameter combinations to determine optimal settings! The main parameters to vary in Stacks are -m (controls minimum number of raw reads required to form a putative allele; ustacks), -M (controls number of mismatches allowed between putative alleles to merge them to a putative locus; ustacks), and -n (controls number of mismatches allowed between putative loci during catalog construction; cstacks). Of these, the default value of -m 3 is quite robust, and you can probably leave it alone. However, -M and -n values will significantly alter your genotype calls, so you should test a range of each.

[Rochette and Catchen 2017](https://www.nature.com/articles/nprot.2017.123) suggest starting by leaving M=n, and testing M1n1-M9n9. In practice, it's highly unlikely that you will allow 9 (or even more than 5) mismatches, so you can probably stop at M5n5. Depending on your dataset, you can also test varying -n relative to -M (e.g. n=M-1 if you only have one population, n=M+1 if you have high polymorphism or for phylogenetics analyses).

__5a. Select test samples and create test population map:__
Testing 5-10 parameter combinations on your full dataset would take a ton of time. Instead, it's better to test parameters using a subset of your samples. Looking at your sample read counts (see 4b), choose ~10-20 representative samples. Ideally, these should represent all of your populations, and sample read coverage should be close to the median of your sample read counts.

Create a population map of these test samples (e.g. named pop_map_test.txt), formatted as in 4c.

__5b. Run Stacks with varying parameter values on test samples:__
Run the full Stacks pipeline on each parameter combination using the denovo_map.pl wrapper. You will be setting up 10-20 Stacks runs. One way to do this efficiently is to write a separate shell script for each parameter combo, and submit all jobs to a SLURM cluster (if you don't know how to use SLURM, see [*here*](https://github.com/caitmcdonald/parallel_computing/blob/master/slurm_scripting.md)).

In order to compare runs, we want to retain SNPs present in 80% of individuals in a population, so be sure to set populations -r 0.8. For example, testing -M 5 -n 5:

    denovo_map.pl -M 5 -T 10 --time-components -o ./stacks_M5n5 --popmap ./cpro_pop_map_test.txt --samples ./samples -X "cstacks:-n 5" -X "populations:-r 0.8"

Make sure to create a unique output directory for every Stacks run so that your output files are not overwritten!

*See sample SLURM* [***script***](cpro_denovo_slurm_M4n4.sh)

__5c. Extract SNP distributions:__
Once you've finished running all parameter combinations, you need to extract the distribution of the number of SNPs per catalog locus from the populations.log.distribs file. We'll use this distribution to generate our plots in step 5d. From the directory above your output directories, you can extract these distrubtions with an awk command. For example, to extract distributions testing M1n1-M9n9:

    for i in 1 2 3 4 5 6 7 8 9
    do
    awk '/snps_per_loc_postfilters/{flag=1; next} /END/{flag=0} flag' stacks_M${i}n${i}/populations.log.distribs > M${i}n${i}.tsv
    done

__5d. Plot output and choose optimal parameters:__
To see what parameter combinations work best, we will plot the number of total loci, polymorphic loci, SNPs, and the percent loci containing n SNPs. There is no firm cutoff or consensus on choosing parameter values, but you should be able to justify your choice. For example, look for the combination that yields a plateau in SNPs/loci retained.

*See sample R* [***script***](cpro_params_test_M1n1M9n9.R)

### Step 6. Run Stacks on the full dataset
Once you've decided on the optimal parameter values, re-run Stacks on all your samples. You can run each component of Stacks separately, or by using the wrapper denovo_map.pl.

__6a. Running denovomap.pl:__ Place your renamed samples (step 4b) and population map (step 4c) into your working directory, create an output directory for Stacks, and run like so (e.g. for parameters -M 2 -n 3):

    mkdir stacks_out
    denovo_map.pl -T 38 --time-components -o ./stacks_out --popmap ./pop_map.txt --samples ./samples_renamed -X "cstacks:-n 3"

__6b. Running populations:__ Using denovo_map.pl runs populations automatically under default conditions. However, you may want to re-run populations to filter inferred genotypes or export results to alternative file formats (e.g. .vcf, .genepop, .structure). Here are some common filtering options you might use:

    -r 0.8               #minimum per population percentage of samples to keep a locus
    --min_maf            #minimum minor allele frequency
    --write_single_snp   #retain only the first snp per locus

It's a good idea to generate two outputs: raw results with no filtering, and raw results with only one SNP per locus (+/- filtering).

### Step 7. Post-Stacks SNP filtering
As with parameter optimizing, there is little consensus regarding how conservatively to filter SNPs, and this will in part depend on your sequencing quality (e.g. if your sequencing depth is lower, you will have less confidence in your genotype calls, and you should filter more conservatively) and the analyses you want to run. At minimum, it's common to remove loci and individuals with high amounts of missing data.

If you want to filter your SNPs more conservatively than by the -r and --min_maf in populations, you can do so in VCFtools. I use the following approach, which is based on [O'Leary et al. 2018](https://onlinelibrary.wiley.com/doi/full/10.1111/mec.14792).

__7a. Filter low-confidence genotypes:__ Using VCF tools, filter SNPs with a minor allele count <3, minimum coverage of 3 reads, and minimum mean coverage of 10 reads:

    vcftools --vcf populations.snps.vcf --mac 3 --minDP 3 --min-meanDP 10 --recode --recode-INFO-all --out cpro_mac3minDP3meanDP10

__7b. Iteratively filter missing genotypes and individuals with high % missing data:__ Iteratively filtering missing data while progressively increasing filter cut-offs retains more high quality SNPs and more individuals than removing missing data in a single step. For example, you can keep only variants successfully genotyped in 50% of individuals:

    vcftools --vcf cpro_mac3minDP3meanDP10.recode.vcf --max-missing 0.5 --recode --recode-INFO-all --out cpro_mac3minDP3meanDP10miss50

Then retain only individuals that are missing <90% of genotypes:

    vcftools --vcf cpro_mac3minDP3meanDP10miss50.recode.vcf --missing-indv
    cat out.imiss | awk '$5 > 0.9' out.imiss | cut -f1 > lowDP.indv
    vcftools --vcf cpro_mac3minDP3meanDP10miss50.recode.vcf --remove lowDP.indv --recode --recode-INFO-all --out cpro_mac3minDP3meanDP10miss50imiss90

And continue to iterate this process until you retain only variants genotyped in >80% of individuals, and only individuals with <50% missing genotypes.
