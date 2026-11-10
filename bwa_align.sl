#!/bin/bash
#SBATCH --job-name=bwa_align
#SBATCH --account=ga03488
#SBATCH --time=12:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-34%10
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail

module purge
module load BWA SAMtools picard

FASTQ_DIR=/nesi/nobackup/ga03488/FAW_data/03_amys_data/sra_cache/fastq
REF=/nesi/nobackup/ga03488/FAW_data/04_new_reference_genome/sfC.ver7.reformat.fa
OUT_DIR=/nesi/nobackup/ga03488/FAW_data/03_amys_data/bams

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)
R1=${FASTQ_DIR}/${SAMPLE}/${SAMPLE}_1.fastq
R2=${FASTQ_DIR}/${SAMPLE}/${SAMPLE}_2.fastq

mkdir -p "$OUT_DIR/tmp"
cd "$OUT_DIR"

#align and coordinate sort
bwa mem -M -t 6 \
    -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:ILLUMINA\tLB:${SAMPLE}" \
    "$REF" "$R1" "$R2" \
  | samtools sort -@ 1 -m 1G -T "tmp/${SAMPLE}" -O bam -o "${SAMPLE}.sorted.bam" -

#mark duplicates
java -Xmx12g -jar "$EBROOTPICARD/picard.jar" MarkDuplicates \
    -ASSUME_SORTED true \
    -I "${SAMPLE}.sorted.bam" \
    -O "${SAMPLE}.dedup.bam" \
    -M "${SAMPLE}.metrics.txt" \
    -TMP_DIR tmp

#index, alignment stats, remove intermediate BAM
samtools index -b "${SAMPLE}.dedup.bam"
samtools flagstat "${SAMPLE}.dedup.bam" > "${SAMPLE}.bamstats.out"
rm "${SAMPLE}.sorted.bam"
