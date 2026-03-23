# Create an output directory for the reports to keep the workspace clean
mkdir -p qc_reports

# Execute FastQC on both read files, directing output to the new directory
fastqc data/reads_1.fq data/reads_2.fq -o qc_reports/