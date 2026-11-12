#!/bin/bash
#SBATCH --job-name=env_nz_pac
#SBATCH --account=ga03488
#SBATCH --time=06:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=2
#SBATCH --output=step8_env_nz_pacific_%j.out

module purge
module load R-Geo/4.3.2-foss-2023a
mkdir -p /nesi/nobackup/ga03488/tmp
Rscript env_nz_pacific2.R
