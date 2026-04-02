#!/bin/bash
echo "Starting Deletion Pipeline..."

# EVIDENCE 1: DISTANCE ANOMALY
# Flag anomalous pairs spanning a gap larger than expected library size.
samtools view -h output/aligned.bam | \
    awk '$1 ~ /^@/ || $9 > 600 || $9 < -600' | \
    samtools view -u - | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 100 | \
    bedtools slop -b 400 -g data/genome.txt > output/del_ev1_flanks.bed

# EVIDENCE 2: SPLIT READS
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/del_ev2_splits.bed

# EVIDENCE 3: COVERAGE GAP
# Use -bga to ensure 0-coverage regions are included.
samtools view -u -f 2 output/aligned.bam | \
    bedtools genomecov -ibam stdin -bga | \
    awk '$4 < 15' | \
    bedtools merge -d 50 | \
    bedtools slop -b 100 -g data/genome.txt > output/del_ev3_void.bed

# INTERSECTION
# Intersect all 3 lines of evidence, sort and merge.
bedtools intersect -a output/del_ev1_flanks.bed -b output/del_ev2_splits.bed | \
    bedtools intersect -a stdin -b output/del_ev3_void.bed | \
    bedtools sort -i stdin | \
    bedtools merge -i stdin > output/candidate_deletions.bed