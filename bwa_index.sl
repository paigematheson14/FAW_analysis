#!/bin/bash -e
#SBATCH --job-name=bwa_index
#SBATCH --account=ga03488
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

#index the genome for all samples. this turns the genome into a searchable data structure (like index of a book)

module purge
module load BWA   

bwa index ../04_new_reference_genome/sfC.ver7.reformat.fa
