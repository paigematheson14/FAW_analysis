# FAW_analysis

1. Download Amy's data from the SRA (amy_data_download.sl)
2. convert sra format to fastq (convert_sra.sl)
3. Check the qc of the raw data using fastqc and multiqc (fastqc.sl)
4. Index reference genome (bwa_index.sl)
5. Align Amy's data to the new reference genome (bwa_align.sl)
6. Align new data to new reference genome (align_new_data.sl)


# Environmental data 
We need a description for all of the environments. Each row will be a location on earth - one pixel covering approx 1km x 1km; each column is an environmental measurement at that spot, e.g., rainful, temperature, % forest, % cropland, etc. 

1. Download the environmental data from 1971-2010 from CHELSA (download_chelsa.sl; check_chelsa.R)
2. Download land cover information from Copernicus (download_landcover.sl)
3. Download crop data for maize, corn, sugarcane, sorgum, cotton and rice from 'https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SWPENT'. The file to choose is 'spam2020V2r2_global_harvested_area.geotiff.zip'. Put this file in your directory and extract the aforementioned target crop data (extract_spam.sl)
4. Build one table from all of these environmental values (climate, landcover, crops) for all of the sampling locations (global) and a matching table and set of maps for NZ and the Pacific islands all on the same 1km grid (env_nz_pacific.R; env_nz_pacific.sl)
