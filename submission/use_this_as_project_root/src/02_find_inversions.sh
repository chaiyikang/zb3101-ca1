#!/bin/bash

echo "Starting Inversion Pipeline..."

# EVIDENCE 1: ORIENTATION ANOMALY
# Extract pairs that map to the SAME chromosome ($7 == "=") but 
# have the SAME strand orientation (FF or RR).
# Deconstruct the SAM FLAG ($2). 
# Bit 16 = read reverse. Bit 32 = mate reverse.
# `int($2/16)%2` isolates the 16 bit. If r == m, they match (both 0 or both 1).
# Key evidence of inversion, unique to inversion out of SVs !!!
samtools view -h -F 2 output/aligned.bam | \
    awk '{ 
        if ($1 ~ /^@/) { print $0; next } 
        r = int($2/16)%2; 
        m = int($2/32)%2; 
        if (r == m && $7 == "=") print $0 
    }' | \
    samtools view -u - | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 100 | \
    bedtools slop -b 400 -g data/genome.txt > output/inv_ev1_flanks.bed

# EVIDENCE 2: SPLIT READS (find the 1bp points of inversion)
# Extract supplementary alignments (-f 2048).
# Captures the individual reads that physically cross the mutation 
# threshold, where one half maps forward and the other half maps reverse.
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/inv_ev2_splits.bed

# INTERSECTION
# This should output the distinct left and right edges of the inverted sequence.
bedtools intersect -a output/inv_ev1_flanks.bed -b output/inv_ev2_splits.bed > output/candidate_inversions_boundaries.bed

echo "Inversion boundary candidates saved to candidate_inversions_boundaries.bed"