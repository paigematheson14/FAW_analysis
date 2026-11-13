#!/bin/bash
#SBATCH --job-name=bwa_align
#SBATCH --account=ga03488
#SBATCH --time=12:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=8
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail

module purge
module load BWA SAMtools picard

FASTQ_DIR=/nesi/nobackup/ga03488/FAW_data/05_2026_faw_genomes/FASTQ_Generation_07_01_2026_5_34_36-937675739
REF=/nesi/nobackup/ga03488/FAW_data/01_bam_french_data/ASSEMBLY/SfrugC_Mito_Wspi.fa
OUT_DIR=/nesi/nobackup/ga03488/FAW_data/07_align_new
SAMPLE_LIST=/nesi/nobackup/ga03488/FAW_data/07_align_new/samples.txt

THREADS=${SLURM_CPUS_PER_TASK}
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

mkdir -p "$OUT_DIR/tmp"
cd "$OUT_DIR"

shopt -s nullglob
LANE_BAMS=()
for DIR in "${FASTQ_DIR}/${SAMPLE}"_L00*-ds.*; do
    LANE=$(basename "$DIR" | grep -oE 'L00[0-9]')
    R1=( "$DIR"/*_R1_001.fastq.gz )
    R2=( "$DIR"/*_R2_001.fastq.gz )

    bwa mem -M -t "$THREADS" \
        -R "@RG\tID:${SAMPLE}.${LANE}\tSM:${SAMPLE}\tPL:ILLUMINA\tLB:${SAMPLE}\tPU:${SAMPLE}.${LANE}" \
        "$REF" "${R1[0]}" "${R2[0]}" \
      | samtools sort -@ 2 -m 1G -T "tmp/${SAMPLE}.${LANE}" -o "${SAMPLE}.${LANE}.sorted.bam" -

    LANE_BAMS+=( "${SAMPLE}.${LANE}.sorted.bam" )
done

samtools merge -@ "$THREADS" -f "${SAMPLE}.sorted.bam" "${LANE_BAMS[@]}"
rm "${LANE_BAMS[@]}"

java -Xmx12g -jar "$EBROOTPICARD/picard.jar" MarkDuplicates \
    -ASSUME_SORTED true \
    -I "${SAMPLE}.sorted.bam" \
    -O "${SAMPLE}.dedup.bam" \
    -M "${SAMPLE}.metrics.txt" \
    -TMP_DIR tmp

samtools index "${SAMPLE}.dedup.bam"
samtools flagstat "${SAMPLE}.dedup.bam" > "${SAMPLE}.bamstats.out"
rm "${SAMPLE}.sorted.bam"
rm "${SAMPLE}.sorted.bam"
