# FAW_analysis

1. Download Amy's data from the SRA (amy_data_download.sl)
2. convert sra format to fastq (convert_sra.sl)
3. Check the qc of the raw data using fastqc and multiqc (fastqc.sl)
4. Index reference genome (bwa_index.sl)
5. Align Amy's data to the new reference genome (bwa_align.sl)


# Environmental data 
We need a description for all of the environments. Each row will be a location on earth - one pixel covering approx 1km x 1km; each column is an environmental measurement at that spot, e.g., rainful, temperature, % forest, % cropland, etc. 

1. Download the environmental data from 1971-2010 from CHELSA (download_chelsa.sl; check_chelsa.R)
2. Download land cover information from Copernicus (download_landcover.sl)
