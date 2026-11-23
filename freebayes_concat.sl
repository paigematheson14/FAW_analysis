#!/bin/bash -e
#SBATCH --job-name=fb_concat
#SBATCH --account=ga03488
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=48:00:00
#SBATCH --output=logs/fb_concat_%j.out
#SBATCH --error=logs/fb_concat_%j.err

ml BCFtools

ls -v fb_chunks/chr*.vcf  > chunks.txt
ls    fb_chunks/MT.vcf   >> chunks.txt

bcftools concat -f chunks.txt | bcftools view -i 'QUAL>20' -Oz -o panel.vcf.gz

bcftools index -t panel.vcf.gz