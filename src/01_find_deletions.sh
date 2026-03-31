#!/bin/bash

echo "Starting Deletion Pipeline..."

# EVIDENCE 1: DISTANCE ANOMALY (The Flanks)
# We use samtools to read the BAM, preserving the header (-h).
# We use awk to keep the header lines ($1 ~ /^@/) AND filter for reads where the 
# insert size (TLEN, column 9) is greater than 600 or less than -600 (distance anomaly).
# We pipe it back to samtools to convert back to binary (-u), extract BED coordinates, 
# merge overlapping reads into solid blocks, and expand the blocks by 400bp using slop.
samtools view -h output/aligned.bam | \
    awk '$1 ~ /^@/ || $9 > 600 || $9 < -600' | \
    samtools view -u - | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 100 | \
    bedtools slop -b 400 -g data/genome.txt > output/del_ev1_flanks.bed

# EVIDENCE 2: SPLIT READS (The Breakpoints)
# -f 2048 extracts strictly the reads that BWA-MEM had to split in half.
# We convert to BED, sort, merge them, and expand the window slightly to ensure intersection.
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/del_ev2_splits.bed

# EVIDENCE 3: THE VOID (Coverage Drop)
# -f 2 strictly extracts perfectly normal "properly paired" reads.
# genomecov creates a map of read depth. We use awk to find spots where depth is < 5x.
samtools view -u -f 2 output/aligned.bam | \
    bedtools genomecov -ibam stdin -bg | \
    awk '$4 < 5' | \
    bedtools merge -d 50 | \
    bedtools slop -b 100 -g data/genome.txt > output/del_ev3_void.bed

# THE INTERSECTION (The Sieve)
# We find exactly where the expanded flanks overlap the expanded splits, 
# and then intersect THAT result with the low-coverage void.
bedtools intersect -a output/del_ev1_flanks.bed -b output/del_ev2_splits.bed | \
    bedtools intersect -a stdin -b output/del_ev3_void.bed > output/candidate_deletions.bed

echo "Deletion candidates saved to candidate_deletions.bed"