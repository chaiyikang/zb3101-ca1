# #!/bin/bash
# echo "Starting Inversion Pipeline..."

# # EVIDENCE 1: ORIENTATION ANOMALY (The Flanks)
# # FIX: Deconstruct the SAM FLAG ($2) to check orientation.
# # Bit 16 (reverse strand). Bit 32 (mate reverse strand).
# # By using modulo math `int($2/16)%2`, we isolate the bits. If r == m, both reads
# # map to the SAME strand (FF or RR), which is the strict mechanical signature of an inversion.
# samtools view -h -F 2 output/aligned.bam | \
#     awk '{ 
#         if ($1 ~ /^@/) { print $0; next } 
#         r = int($2/16)%2; 
#         m = int($2/32)%2; 
#         if (r == m && $7 == "=") print $0 
#     }' | \
#     samtools view -u - | \
#     bedtools bamtobed -i stdin | \
#     bedtools sort -i stdin | \
#     bedtools merge -d 100 | \
#     bedtools slop -b 400 -g data/genome.txt > output/inv_ev1_flanks.bed

# # EVIDENCE 2: SPLIT READS (The Boundaries)
# samtools view -u -f 2048 output/aligned.bam | \
#     bedtools bamtobed -i stdin | \
#     bedtools sort -i stdin | \
#     bedtools merge -d 50 | \
#     bedtools slop -b 400 -g data/genome.txt > output/inv_ev2_splits.bed

# # EVIDENCE 3: NORMAL COVERAGE BOUNDARY
# # FIX: An inversion does not alter copy number. To prevent the insertion 'source' 
# # from bleeding into this file, we mandate that proper pair coverage remains normal.
# samtools view -u -f 2 output/aligned.bam | \
#     bedtools genomecov -ibam stdin -bga | \
#     awk '$4 >= 15 && $4 <= 25' | \
#     bedtools merge -d 50 | \
#     bedtools slop -b 100 -g data/genome.txt > output/inv_ev3_normal.bed

# # THE INTERSECTION
# bedtools intersect -a output/inv_ev1_flanks.bed -b output/inv_ev2_splits.bed | \
#     bedtools intersect -a stdin -b output/inv_ev3_normal.bed > output/candidate_inversions.bed

#!/bin/bash

echo "Starting Inversion Pipeline..."

# ---------------------------------------------------------
# EVIDENCE 1: ORIENTATION ANOMALY (The Breakpoint Flanks)
# ---------------------------------------------------------
# Action: Extract pairs that map to the SAME chromosome ($7 == "=") but 
# have the SAME strand orientation (FF or RR).
# Mapping: We deconstruct the SAM FLAG ($2). 
# Bit 16 = read reverse. Bit 32 = mate reverse.
# `int($2/16)%2` isolates the 16 bit. If r == m, they match (both 0 or both 1).
# This is the definitive mechanical signature of an inversion breakpoint.
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

# ---------------------------------------------------------
# EVIDENCE 2: SPLIT READS (The Exact 1bp Boundaries)
# ---------------------------------------------------------
# Action: Extract supplementary alignments (-f 2048).
# Mapping: Captures the individual reads that physically cross the mutation 
# threshold, where one half maps forward and the other half maps reverse.
samtools view -u -f 2048 output/aligned.bam | \
    bedtools bamtobed -i stdin | \
    bedtools sort -i stdin | \
    bedtools merge -d 50 | \
    bedtools slop -b 400 -g data/genome.txt > output/inv_ev2_splits.bed

# ---------------------------------------------------------
# THE INTERSECTION LOGIC (The Boundary Sieve)
# ---------------------------------------------------------
# Action: Intersect ONLY Ev1 and Ev2.
# Mapping: We do NOT enforce an Ev3 coverage rule here because normal proper-pair 
# coverage fundamentally drops to 0 precisely at the breakpoint. 
# This will output the distinct left and right edges of the inverted sequence.
bedtools intersect -a output/inv_ev1_flanks.bed -b output/inv_ev2_splits.bed > output/candidate_inversions_boundaries.bed

echo "Inversion boundary candidates saved to candidate_inversions_boundaries.bed"