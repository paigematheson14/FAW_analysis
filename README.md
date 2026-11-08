# FAW_analysis

1. Download Amy's data from the SRA (amy_data_download.sl)
2. convert sra format to fastq (convert_sra.sl)
3. Check the qc of the raw data using fastqc and multiqc (fastqc.sl)
4. Index reference genome (bwa_index.sl)
5. Align Amy's data to the new reference genome (align_array.sl)
