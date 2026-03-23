samtools view -F 2 data/alignment.bam > output/discordant_pairs.sam

samtools view -f 2048 data/alignment.bam > output/split_reads.sam