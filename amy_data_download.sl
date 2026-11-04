#!/bin/bash -e
#SBATCH --job-name=sra_dl
#SBATCH --account=ga03488
#SBATCH --time=06:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=6
#SBATCH --array=1-34%6 
#SBATCH --output=logs/%x_%A_%a.out

module purge
module load sratoolkit/3.0.2
module load pigz

SRR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" accessions.txt)

prefetch "$SRR" --max-size u -O sra_cache
fasterq-dump sra_cache/"$SRR" --split-files -e $SLURM_CPUS_PER_TASK -O fastq -t $TMPDIR
pigz -p $SLURM_CPUS_PER_TASK fastq/${SRR}*.fastq
rm -rf sra_cache/"$SRR"      