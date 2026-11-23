#!/bin/bash -e
#SBATCH --job-name=freebayes_panel
#SBATCH --account=ga03488
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=logs/fb_%A_%a.out
#SBATCH --error=logs/fb_%A_%a.err

# Joint freebayes calling on the reference panel, in 100 kb chunks, same parameters as Mathieu

REF=../01_bam_french_data/ASSEMBLY/SfrugC_Mito_Wspi.fa
BAMLIST=bam.leg.list
CHUNKS=Sfrug.chunks100kb
PER_TASK=50

module purge
module load FreeBayes/1.3.10-GCC-12.3.0

mkdir -p fb_chunks

run_chunk() { #takes one chunk
  r=$1
  out="fb_chunks/${r/:/_}.vcf" #build an output replacing : with _ (e.g., chr1:1-100000.vcf)
  [ -e "$out" ] && return 0 #skip if it already exists (to prevent having to run a bunch of times from the beginning - only unfinished chunks get processed)
  freebayes -f "$REF" -L "$BAMLIST" -r "$r" -K -C 1 -F 0.01 -G 5 -E -1 --limit-coverage 500 -n 4 -m 30 -q 20 > "$out.tmp" && mv "$out.tmp" "$out" #run freebayes on each region first writing to tmp.vcf and then to .vcf only when the run is a success - crashed/killed jobs are left as partial files. 
}
export -f run_chunk
export REF BAMLIST

#the freebayes options are:
#-f = the reference fasta
#-L a text file containing a list of all of the bam file paths
#-r $r = making sure to restrict each freebayes run to the region speciified
#-K = outputs all alleles passing the input filters regardless of genotyping outcome
#-C 1 requires at least 1 supporting read for an alternate allele
#-F 0.01 requires at least 1% alternate allele fraction
#-G 5 requires the alternate allele in at least 5 reads across samples 
#-E -1 disable clumping of nearby variants into complex haplotypes
#--limit-coverage 500 - downsample to at most 500x per position
#-n 4 considers only the top 4 alternate alleles per site
#-m = 30 minimum mapping quality of 30
#-q 20 minimum base quality of 20 

#these thresholds are quite permissive because we have pooled samples and rather low frequency variant detection so we will also do quite a strict filter down stream because there is likely to be a lot of false positives.


sed -n "${start},${end}p" "$CHUNKS" | awk '{print $1}' | \
  xargs -P "$SLURM_CPUS_PER_TASK" -I{} bash -c 'run_chunk "$@"' _ {}