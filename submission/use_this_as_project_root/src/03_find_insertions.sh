#!/bin/bash
echo "Starting Endogenous Insertion Pipeline..."

# EVIDENCE 1: ANOMALOUS PAIRS (Target & Source Flanks)
# Captures cross-chromosome mappings or massive distance anomalies bridging the two loci.
samtools view -h -F 2 output/aligned.bam | \
    awk '$1 ~ /^@/ || $7 != "=" || ($7 == "=" && ($9 > 600 || $9 < -600))' | \
    samtools view -u - | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 100 | \
    bedtools slop -b 400 -g data/genome.txt > output/ins_ev1_flanks.bed

# EVIDENCE 2: SPLIT READS
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/ins_ev2_splits.bed

# EVIDENCE 3: COVERAGE SPIKE
samtools view -u -f 2 output/aligned.bam | \
    bedtools genomecov -ibam stdin -bga | \
    awk '$4 > 25' | \
    bedtools merge -d 50 | \
    bedtools slop -b 100 -g data/genome.txt > output/ins_ev3_spike.bed

# INTERSECTION
# The Target: Has the structural anomalies, but lacks the copy number spike.
# 1 intersect 2 subtract 3
bedtools intersect -a output/ins_ev1_flanks.bed -b output/ins_ev2_splits.bed | \
    bedtools subtract -a stdin -b output/ins_ev3_spike.bed | \
    bedtools sort -i stdin | \
    bedtools merge -i stdin > output/candidate_insertions_TARGET.bed

# The Source: Has the structural anomalies AND the copy number spike.
# intersect 1, 2, 3
bedtools intersect -a output/ins_ev1_flanks.bed -b output/ins_ev2_splits.bed | \
    bedtools intersect -a stdin -b output/ins_ev3_spike.bed | \
    bedtools sort -i stdin | \
    bedtools merge -i stdin > output/candidate_insertions_SOURCE.bed

echo "Target candidates saved to candidate_insertions_TARGET.bed"
echo "Source candidates saved to candidate_insertions_SOURCE.bed"