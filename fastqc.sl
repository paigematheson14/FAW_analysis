#!/bin/bash -e
#SBATCH --job-name=fastqc
#SBATCH --account=ga03488
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=16
#SBATCH --output=fastqc_%A_%a.out
#SBATCH --error=fastqc_%A_%a.err

module purge
ml FastQC
ml MultiQC

fastqc -t 16 -o fastqc_out/ SRR336*/*.fastq
multiqc fastqc_out/ -o multiqc_out/

