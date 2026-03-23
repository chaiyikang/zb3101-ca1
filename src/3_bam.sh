# Convert SAM to BAM, sort it by coordinates, and output as a new file
# samtools sort -O BAM -o data/alignment.bam data/alignment.sam

# samtools index data/alignment.bam

samtools flagstat data/alignment.bam

3222541 + 0 in total (QC-passed reads + QC-failed reads)
3222520 + 0 primary
0 + 0 secondary
21 + 0 supplementary
0 + 0 duplicates
0 + 0 primary duplicates
3222541 + 0 mapped (100.00% : N/A)
3222520 + 0 primary mapped (100.00% : N/A)
3222520 + 0 paired in sequencing
1611260 + 0 read1
1611260 + 0 read2
3222174 + 0 properly paired (99.99% : N/A)
3222520 + 0 with itself and mate mapped
0 + 0 singletons (0.00% : N/A)
286 + 0 with mate mapped to a different chr
286 + 0 with mate mapped to a different chr (mapQ>=5)