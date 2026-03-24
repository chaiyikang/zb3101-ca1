#!/bin/bash

# 1. Extract and sort Discordant Pairs
# -F 2 flags reads that are NOT properly paired
echo "Extracting and sorting discordant pairs..."
samtools view -u -F 2 data/alignment.bam | samtools sort -o output/discordant_pairs.sorted.bam
samtools index output/discordant_pairs.sorted.bam

# 2. Extract and sort Split Reads (Supplementary Alignments)
# -f 2048 strictly flags reads split across structural breakpoints
echo "Extracting and sorting split reads..."
samtools view -u -f 2048 data/alignment.bam | samtools sort -o output/split_reads.sorted.bam
samtools index output/split_reads.sorted.bam


echo "Execution complete. Binaries ready for IGV."