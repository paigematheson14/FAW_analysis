#!/bin/bash
#SBATCH --job-name=spam_unzip
#SBATCH --account=ga03488
#SBATCH --time=00:15:00
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1
#SBATCH --output=extract_spam_%j.out

#extract MapSPAM 2020 harvested area for 6 crops - maize, sorghum, rice, wheat, cotton, sugarcane

unzip -o -j spam2020V2r2_global_harvested_area.geotiff.zip -d spam_raw \
  '*_MAIZ_A.tif' '*_SORG_A.tif' '*_RICE_A.tif' '*_WHEA_A.tif' '*_COTT_A.tif' '*_SUGC_A.tif'
