#!/bin/bash

echo "Starting Inversion Pipeline..."

# EVIDENCE 1: ORIENTATION ANOMALY (The Flanks)
# -F 2 flags all reads that are NOT properly paired.
# To isolate inversions from deletions/insertions, we use awk to ensure the mate 
# is on the same chromosome ($7 == "=") AND the insert size is normal (-600 to 600).
# This strictly isolates the FF and RR orientation anomalies.
samtools view -h -F 2 output/aligned.bam | \
    awk '$1 ~ /^@/ || ($7 == "=" && $9 > -600 && $9 < 600)' | \
    samtools view -u - | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 100 | \
    bedtools slop -b 400 -g data/genome.txt > output/inv_ev1_flanks.bed

# EVIDENCE 2: SPLIT READS (The Boundaries)
# Inversions also split reads, but one half maps to the reverse strand.
# We extract all splits just like we did for deletions.
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/inv_ev2_splits.bed

# THE INTERSECTION
# For inversions, the coverage drop only occurs precisely at the 1bp boundary, 
# making Evidence 3 hard to capture via automation. So we just intersect Ev1 and Ev2.
bedtools intersect -a output/inv_ev1_flanks.bed -b output/inv_ev2_splits.bed > output/candidate_inversions.bed

echo "Inversion candidates saved to candidate_inversions.bed"