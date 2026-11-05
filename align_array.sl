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
SAMPLE_LIST=samples.txt

THREADS=${SLURM_CPUS_PER_TASK}
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

# Check sample and input files
if [[ -z "$SAMPLE" ]]; then
    echo "ERROR: No sample found for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

R1=${FASTQ_DIR}/${SAMPLE}/${SAMPLE}_1.fastq
R2=${FASTQ_DIR}/${SAMPLE}/${SAMPLE}_2.fastq

[[ -f "$R1" ]] || { echo "Missing R1: $R1"; exit 1; }
[[ -f "$R2" ]] || { echo "Missing R2: $R2"; exit 1; }

mkdir -p "$OUT_DIR" "$OUT_DIR/tmp"
cd "$OUT_DIR"

echo "Starting sample: $SAMPLE"
echo "Start time: $(date)"

#Align and coordinate sort
bwa mem -M -t 6 \
    -R "@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:ILLUMINA\tLB:${SAMPLE}" \
    "$REF" "$R1" "$R2" \
  | samtools sort -@ 1 -m 1G \
      -T "tmp/${SAMPLE}" \
      -O bam \
      -o "${SAMPLE}.sorted.bam" -

#Mark duplicates
java -Xmx12g -jar "$EBROOTPICARD/picard.jar" MarkDuplicates \
    -ASSUME_SORTED true \
    -I "${SAMPLE}.sorted.bam" \
    -O "${SAMPLE}.dedup.bam" \
    -M "${SAMPLE}.metrics.txt" \
    -TMP_DIR "tmp"

#Index BAM
samtools index -b "${SAMPLE}.dedup.bam"

#Generate alignment statistics
samtools flagstat "${SAMPLE}.dedup.bam" > "${SAMPLE}.bamstats.out"

#Remove intermediate BAM
rm "${SAMPLE}.sorted.bam"

echo "Finished sample: $SAMPLE"
echo "End time: $(date)"
