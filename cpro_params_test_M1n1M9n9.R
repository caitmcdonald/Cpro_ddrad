######

# Script to plot SNP distributions from STACKS output with varying parameters

# This script will:
# 1) Generate total loci, polymorphic loci, and total SNP counts for each input file
# 2) Plot these values
# 3) Plot the distribution of SNPs per locus

# From these plots, you can determine the optimal values for STACKS parameters -m, -M, and -n

# Precondition: .tsv (or other format) files with SNP distributions (e.g. M2_snp_distribution.tsv), generated from cpro_stacks_optimize_extract.sh

######

library(dplyr)
library(data.table)
library(ggplot2)
library(limma)
library(gridExtra)

setwd("/Users/caitlinannmcdonald/cpro_ddrad/cpro_03_STACKS/cpro_02_params_testing/cpro_params_compare_new/")

#### Varying M and n (M1n1 to M9n9) ####
files <- list.files(path = "/Users/caitlinannmcdonald/cpro_ddrad/cpro_03_STACKS/cpro_02_params_testing/cpro_params_compare/", pattern="*.tsv", full.names = T)

# read file name
filenames <- basename(files)
filenames <- as.data.frame(removeExt(filenames))
filenames <- cbind(filenames, c(1:9))
names(filenames) <- c("Test","M")

count <- 1
for (i in files[1:9]){
  table <- read.delim(i, skip=1, header=T)
  table$n_loci_percent<- table$n_loci/sum(table$n_loci)
  table$m<- count
  write.table(table, "distributions.txt", append=T, row.names=F, col.names = F)
  loci_snps <- data.frame("n_loci"=sum(table$n_loci), "n_poly_loci"=sum(table$n_loci[-1]), "n_snps"=(sum(table$n_snps*table$n_loci)))
  write.table(loci_snps, "counts.txt", append=T, row.names=F, col.names = F)
  count <- count + 1
}


counts<-read.delim("counts.txt", sep=" ", header=F)
counts <- bind_cols(filenames, counts)
names(counts)<-c("Test", "M", "n_loci","n_poly_loci","n_snps")

# Total assembled loci
tot_loci <- ggplot(data=counts, aes(x=Test, y=n_loci)) +
  geom_point() + theme_classic() 
tot_loci

# Polymorphic loci
poly_loci <- ggplot(data=counts, aes(x=Test, y=n_poly_loci)) +
  geom_point() + theme_classic() 
poly_loci

# Total and polymorphic together
all_loci <- ggplot(data=counts, aes(x=Test, y=value, color=Loci)) +
  geom_point(aes(y=n_loci, col="Total")) +
  geom_point(aes(y=n_poly_loci, col="Polymorphic")) +
  theme_classic(base_size = 8) + xlab("Test") + ylab("Count")
all_loci

# Total SNPs
tot_snps <- ggplot(data=counts, aes(x=Test, y=n_snps)) +
  geom_point() + theme_classic() 
tot_snps

# Percent of loci with # of SNPs
snp_table<-read.delim("distributions.txt", sep=" ", header=F)
names(snp_table)<- c("n_snps","n_loci", "n_loci_percent", "M") 
snp_table <- left_join(snp_table, filenames)
snp_table$n_loci_percent<-snp_table$n_loci_percent*100
snp_table$n_snps<-ifelse(snp_table$n_snps < 9, snp_table$n_snps, "9 +")
snp_table$n_snps<-as.factor(snp_table$n_snps)
snp_table$Test <- factor(snp_table$Test, levels=x)

percent_loci<-ggplot(data = snp_table) + 
  geom_col(aes(x=n_snps, y=n_loci_percent, fill=Test), position="dodge") + 
  scale_fill_brewer(palette="Spectral", direction=1) + 
  xlab("# SNPs per locus") + 
  ylab("% loci") +
  theme_classic(base_size = 8) 
percent_loci

#pdf("params_test.pdf", width=8, height=4)
grid.arrange(all_loci, percent_loci, ncol=2)
#dev.off()
