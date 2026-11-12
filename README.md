# FAW_analysis
## Download all of the data and align to the new reference genome (https://bipaa.genouest.org/sp/spodoptera_frugiperda_corn/download/spodoptera_frugiperda_corn/assembly_7.0/fasta/)
1. Download Amy's data from the SRA (amy_data_download.sl)
2. convert sra format to fastq (convert_sra.sl)
3. Check the qc of the raw data using fastqc and multiqc (fastqc.sl)
4. Index reference genome (bwa_index.sl)
5. Align Amy's data to the new reference genome (bwa_align.sl)
6. Check the QC of the new NZ/pacific genomes (I just used fastqc.sl again and updated a few of the paths)
7. Align new data to new reference genome (align_new_data.sl)

## Variant calling
We will create a reference list of trustworthy SNPs from a subset of good quality samples with high coverage using freebayes and use this dataset to train GATK for the rest of the samples. 
1. Create a list of all of the samples we have and where they are stored ```ls ../01_bam_french_data/bam_files_public/*.bam ../03_amys_data/bams/*.bam ../07_align_new/*.bam > all.bams.list```


# Environmental data 
We need a description for all of the environments. Each row will be a location on earth - one pixel covering approx 1km x 1km; each column is an environmental measurement at that spot, e.g., rainful, temperature, % forest, % cropland, etc. Might not use crop/landcover data because it might add little information to the model (check with Louise, Manpreet, Ang)

1. Download the environmental data from 1971-2010 from CHELSA (download_chelsa.sl; check_chelsa.R)
2. Download land cover information from ESA WorldCover 2021 (download_worldcover.sl)
3. Download crop data for maize, corn, sugarcane, sorgum, cotton and rice from 'https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SWPENT'. The file to choose is 'spam2020V2r2_global_harvested_area.geotiff.zip'. Put this file in your directory and extract the aforementioned target crop data (extract_spam.sl)
4. Build one table from all of these environmental values (climate, landcover, crops) for all of the sampling locations (global) and a matching table and set of maps for NZ and the Pacific islands all on the same 1km grid (env_nz_pacific2.R; env_nz_pacific.sl)
