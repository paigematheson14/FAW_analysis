#!/bin/bash -e

#SBATCH --job-name=fasterq
#SBATCH --account=ga03488
#SBATCH --time=08:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --array=0-33%4
#SBATCH --output=logs/fasterq_%A_%a.out
#SBATCH --error=logs/fasterq_%A_%a.err

module load sratoolkit/3.0.2

# Pick this task's sample
mapfile -t samples < sra_files.txt
sra_file="${samples[$SLURM_ARRAY_TASK_ID]}"
sample=$(basename "$(dirname "$sra_file")")

echo "Processing: $sample"
echo "Input: $sra_file"

mkdir -p "fastq/$sample"

TMP_WORK="/nesi/nobackup/ga03488/tmp/fasterq_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMP_WORK"
trap 'rm -rf "$TMP_WORK"' EXIT   # always clean up, even on failure

fasterq-dump "$sra_file" \
    --split-files \
    --threads "$SLURM_CPUS_PER_TASK" \
    --mem 2G \
    --temp "$TMP_WORK" \
    --outdir "fastq/$sample"

echo "Finished: $sample"
ls -lh "fastq/$sample"