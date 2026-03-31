#!/bin/bash

echo "Starting Insertion Pipeline..."

# awk logic:
# 1. $1 ~ /^@/ : Keep the header.
# 2. $7 != "=" : Mate is on a DIFFERENT chromosome.
# 3. ($7 == "=" && ($9 > 600 || $9 < -600)) : Mate is on the SAME chromosome, but outside the normal 350bp library size.
samtools view -h -F 2 output/aligned.bam | \
    awk '$1 ~ /^@/ || $7 != "=" || ($7 == "=" && ($9 > 600 || $9 < -600))' | \
    samtools view -u - | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 100 | \
    bedtools slop -b 400 -g data/genome.txt > output/ins_ev1_flanks.bed

# EVIDENCE 2: SPLIT READS (The Junction)
# Extract all split alignments. One part of this read will map to the original sequence, 
# the other will map to the inserted sequence.
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/ins_ev2_splits.bed

# THE INTERSECTION
bedtools intersect -a output/ins_ev1_flanks.bed -b output/ins_ev2_splits.bed > output/candidate_insertions.bed

echo "Insertion candidates saved to candidate_insertions.bed"