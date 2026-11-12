#!/bin/bash
#SBATCH --job-name=bwa_align
#SBATCH --account=ga03488
#SBATCH --time=12:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=8
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

# Run from 07_align_new (needs a logs/ folder there):
#   sbatch --array=1 bwa_align_lanes.sl        # test one sample
#   sbatch --array=2-96%10 bwa_align_lanes.sl  # the other 95, 10 at a time

# Stop the job if any command fails
set -euo pipefail

module purge
module load BWA SAMtools picard

# Input/output paths
FASTQ_DIR=/nesi/nobackup/ga03488/FAW_data/05_2026_faw_genomes/FASTQ_Generation_07_01_2026_5_34_36-937675739
REF=/nesi/nobackup/ga03488/FAW_data/04_new_reference_genome/sfC.ver7.reformat.fa
OUT_DIR=/nesi/nobackup/ga03488/FAW_data/07_align_new
SAMPLE_LIST=/nesi/nobackup/ga03488/FAW_data/07_align_new/samples.txt

THREADS=${SLURM_CPUS_PER_TASK}

# Pick this job's sample: array task N takes line N of samples.txt
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

mkdir -p "$OUT_DIR/tmp"
cd "$OUT_DIR"

# Each sample has two lane folders (L001, L002); align each lane separately
for DIR in "${FASTQ_DIR}/${SAMPLE}"_L00*-ds.*; do
    LANE=$(basename "$DIR" | grep -oE 'L00[0-9]')
    R1=$(ls "$DIR"/*_R1_001.fastq.gz)
    R2=$(ls "$DIR"/*_R2_001.fastq.gz)

    # Align reads to the reference and sort by position.
    # Read group: unique ID per lane, same SM (sample name) so lanes merge as one sample
    bwa mem -M -t "$THREADS" \
        -R "@RG\tID:${SAMPLE}.${LANE}\tSM:${SAMPLE}\tPL:ILLUMINA\tLB:${SAMPLE}\tPU:${SAMPLE}.${LANE}" \
        "$REF" "$R1" "$R2" \
      | samtools sort -@ 2 -m 1G -T "tmp/${SAMPLE}.${LANE}" -o "${SAMPLE}.${LANE}.sorted.bam" -
done

# Merge the two lane BAMs into one BAM per sample, then delete the lane BAMs
samtools merge -@ "$THREADS" -f "${SAMPLE}.sorted.bam" "${SAMPLE}".L00*.sorted.bam
rm "${SAMPLE}".L00*.sorted.bam

# Mark PCR/optical duplicates (they stay in the BAM but are flagged)
java -Xmx12g -jar "$EBROOTPICARD/picard.jar" MarkDuplicates \
    -ASSUME_SORTED true \
    -I "${SAMPLE}.sorted.bam" \
    -O "${SAMPLE}.dedup.bam" \
    -M "${SAMPLE}.metrics.txt" \
    -TMP_DIR tmp

# Index the final BAM (creates .bai, needed by most downstream tools)
samtools index "${SAMPLE}.dedup.bam"

# Alignment summary: % mapped, % properly paired, duplicates
samtools flagstat "${SAMPLE}.dedup.bam" > "${SAMPLE}.bamstats.out"

# Delete the intermediate merged BAM (dedup.bam is the one to keep)
rm "${SAMPLE}.sorted.bam"
