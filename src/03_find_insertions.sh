#!/bin/bash

echo "Starting Endogenous Insertion Pipeline..."

# ---------------------------------------------------------
# EVIDENCE 1: ANOMALOUS PAIRS (Target & Source Flanks)
# ---------------------------------------------------------
# Action: Extract pairs where the mate is on a different chromosome ($7 != "=") 
# OR maps outside the expected library insert size of 600bp.
# Mapping: Identifies the spatial bridge between the Target and the Source.
samtools view -h -F 2 output/aligned.bam | \
    awk '$1 ~ /^@/ || $7 != "=" || ($7 == "=" && ($9 > 600 || $9 < -600))' | \
    samtools view -u - | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 100 | \
    bedtools slop -b 400 -g data/genome.txt > output/ins_ev1_flanks.bed

# ---------------------------------------------------------
# EVIDENCE 2: SPLIT READS (The Junctions)
# ---------------------------------------------------------
# Action: Extract supplementary alignments (-f 2048).
# Mapping: Pinpoints the exact 1bp boundaries at both the Target (the insertion 
# breakpoint) and the Source (the edges of the copied sequence).
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/ins_ev2_splits.bed

# ---------------------------------------------------------
# EVIDENCE 3: COVERAGE SPIKE (The Source Identifier)
# ---------------------------------------------------------
# Action: Extract properly paired reads (-f 2), calculate depth, and filter 
# for regions exceeding standard 20x coverage.
# Mapping: A threshold of >25x captures both heterozygous (~30x) and 
# homozygous (~40x) duplications of the Source sequence, while filtering 
# out normal Poisson sequencing noise.
samtools view -u -f 2 output/aligned.bam | \
    bedtools genomecov -ibam stdin -bg | \
    awk '$4 > 25' | \
    bedtools merge -d 50 | \
    bedtools slop -b 100 -g data/genome.txt > output/ins_ev3_spike.bed

# ---------------------------------------------------------
# THE INTERSECTION LOGIC (Isolating Target vs. Source)
# ---------------------------------------------------------

# THE TARGET (The Breakpoint):
# The target locus will have anomalous pairs and split reads, but NO coverage spike 
# (the flanks remain at ~20x baseline). We intersect Ev1 and Ev2, then subtract (-) Ev3 
# to explicitly filter out the source regions.
bedtools intersect -a output/ins_ev1_flanks.bed -b output/ins_ev2_splits.bed | \
    bedtools subtract -a stdin -b output/ins_ev3_spike.bed > output/candidate_insertions_TARGET.bed

# THE SOURCE (The Copied Sequence):
# The source locus will have all three lines of evidence intersecting: anomalous pairs 
# linking back to the target, split reads at the duplication boundaries, AND the >25x coverage spike.
bedtools intersect -a output/ins_ev1_flanks.bed -b output/ins_ev2_splits.bed | \
    bedtools intersect -a stdin -b output/ins_ev3_spike.bed > output/candidate_insertions_SOURCE.bed

echo "Target candidates saved to candidate_insertions_TARGET.bed"
echo "Source candidates saved to candidate_insertions_SOURCE.bed"