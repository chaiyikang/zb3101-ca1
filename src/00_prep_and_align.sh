#!/bin/bash

mkdir -p output

# 1. INDEX THE REFERENCE GENOME
echo "Indexing reference genome..."
bwa index data/reference.fa

# 2. CREATE A CHROMOSOME SIZES FILE (Required for bedtools later)
# samtools faidx creates a .fai index file. We then use 'cut' to extract just the 
# chromosome names (column 1) and their total lengths (column 2) into a text file.
echo "Extracting chromosome boundaries..."
samtools faidx data/reference.fa
cut -f1,2 data/reference.fa.fai > data/genome.txt

# 3. ALIGNMENT & COMPRESSION
# bwa mem maps the reads. We immediately pipe (|) the raw text output (.sam) 
# into samtools sort to convert it into a memory-optimized, coordinate-sorted binary (.bam).
echo "Aligning reads and converting to sorted BAM..."
bwa mem data/reference.fa data/reads_1.fq data/reads_2.fq | samtools sort -o output/aligned.bam

# 4. INDEX THE BAM FILE
# Creates aligned.bam.bai, which is required by IGV to load the alignments.
echo "Indexing BAM file..."
samtools index output/aligned.bam

echo "Prep complete. Primary ledger 'aligned.bam' is ready."