#!/bin/bash -e
#SBATCH --job-name=freebayes_panel
#SBATCH --account=ga03488
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=logs/fb_%A_%a.out
#SBATCH --error=logs/fb_%A_%a.err

# Joint freebayes calling on the reference panel, in 100 kb chunks, same parameters as Mathieu

REF=../01_bam_french_data/ASSEMBLY/SfrugC_Mito_Wspi.fa
BAMLIST=bam.leg.list
CHUNKS=Sfrug.chunks100kb.nuclear
PER_TASK=50

module purge
module load FreeBayes/1.3.10-GCC-12.3.0

mkdir -p fb_chunks

start=$(( (SLURM_ARRAY_TASK_ID - 1) * PER_TASK + 1 ))
end=$(( start + PER_TASK - 1 ))

run_chunk() {
  r=$1
  out="fb_chunks/${r/:/_}.vcf"
  [ -e "$out" ] && return 0
  freebayes -f "$REF" -L "$BAMLIST" -r "$r" \
    -K -C 1 -F 0.01 -G 5 -E -1 --limit-coverage 500 -n 4 -m 30 -q 20 \
    > "$out.tmp" && mv "$out.tmp" "$out"
}
export -f run_chunk
export REF BAMLIST

sed -n "${start},${end}p" "$CHUNKS" | awk '{print $1}' | \
  xargs -P "$SLURM_CPUS_PER_TASK" -I{} bash -c 'run_chunk "$@"' _ {}