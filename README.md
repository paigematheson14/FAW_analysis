# FAW_analysis
## Download all of the data and align to the new reference genome (sfC.ver7.reformat.fa)
1. Download Amy's data from the SRA (amy_data_download.sl)
2. convert sra format to fastq (convert_sra.sl)
3. Check the qc of the raw data using fastqc and multiqc (fastqc.sl)
4. Index reference genome (bwa_index.sl)
5. Align Amy's data to the new reference genome (bwa_align.sl)
6. Check the QC of the new NZ/pacific genomes (I just used fastqc.sl again and updated a few of the paths)
7. Align new data to new reference genome (align_new_data.sl)

## Variant calling
We will create a reference list of trustworthy SNPs from a subset of good quality samples with high coverage using freebayes and use this dataset to train GATK for the rest of the samples. 
1. Create a list of all of the samples we have and where they are stored (```ls ../01_bam_french_data/bam_files_public/*.bam ../03_amys_data/bams/*.bam ../07_align_new/*.bam > all.bams.list```)
2. Pick the top samples from NZ and Fiji (in terms of coverage) to add to the samples that the French team chose for the training dataset. Based on Matieu's notes we want max 5 individuals from any given locality with coverage greater than 10X and <200X. 
3. Check that all of them are aligned to the same reference genome (I did this and found out that my NZ samples were aligned to a slightly different version of the reference genome, e.g., without mitochondrial, so had to realign my NZ/Pacific samples to the same genome as the French team
4. Create a txt file that has the path to the bams that we want to use (e.g., bam.leg.list)
5. Split the S. frug genome into 100kb chunks (French team did this already)
6. Remove Wolbachia chunks ```grep -vE '^(MT|Wspic)[:[:space:]]' ../01_bam_french_data/Sfrug.chunks100kb > Sfrug.chunks100kb.nuclear```
7. Perform FreeBayes on the smaller dataset (freebayes.sl); FIRST Do: ```PER_TASK=50``` ```n=$(wc -l < ../01_bam_french_data/Sfrug.chunks100kb.nuclear)```, then submit as ```sbatch --array=1-$(( (n + PER_TASK - 1) / PER_TASK )) freebayes.sl```
8. Concatenate all the chunks (freebayes_concatenate.sl)
9. Do a clean up of the vcf first to keep only QUAL >= 20 and biallelic sites, decomposes complex alleles with vcfwave, normalises, keeps SNPs only, sorts, and removes duplicates (bcftools_filter_panel.sl)
10. Filter for quality - remove false positives using the INFO statistics: depth window per chromosome (centred on each peak because 8 of the chromosomes had binomial distributions in depth?), NS, minor allele fraction, read-placement balance, strand and end-placement bias, and mapping-quality ratio. This script also drops MT and chr24 because MT was crazy and chr24 was extremely poor. 

# Environmental data 
We need a description for all of the environments. Each row will be a location on earth - one pixel covering approx 1km x 1km; each column is an environmental measurement at that spot, e.g., rainful, temperature, % forest, % cropland, etc. Might not use crop/landcover data because it might add little information to the model (check with Louise, Manpreet, Ang)
