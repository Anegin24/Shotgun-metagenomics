KRAKEN2_DB="/data01/runs/Metagenomic/krakendb/krakendatabasestandard/"
INPUT_DIR="/data01/runs/Metagenomic/LongShortRead/short/assembled/"
find "$INPUT_DIR" -type f \( -name "*.contigs.fa.gz" -o -name "*.scaffolds.fasta.gz" \) | while read -r SAMPLE; do
    # Extract the sample name by removing the file extension (e.g., sample.contigs.fasta.gz -> sample)
    SAMPLE_NAME=$(basename "$SAMPLE" .fa.gz)

    # Extract original name without "contigs" or "scaffolds"
    # Extract original name without "contigs" or "scaffolds"
    ORIGINAL_NAME=${SAMPLE_NAME%.*}
    ORIGINAL_NAME=${ORIGINAL_NAME%_contigs}
    ORIGINAL_NAME=${ORIGINAL_NAME%_scaffolds}

    # Define output directory and file paths for Kraken2 and Bracken results
    OUTPUT_DIR="${INPUT_DIR}/${ORIGINAL_NAME}/kraken2_${SAMPLE_NAME}"
    OUTPUT_KRAKEN2_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.assembly.kraken2"
    REPORT_KRAKEN2_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.assembly.kraken2.report.txt"
    REPORT_MPA_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.assembly.kraken2.mpa"

    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"

    # Run Kraken2 classification with specified database and options
    kraken2 --db "$KRAKEN2_DB" \
        --output "$OUTPUT_KRAKEN2_FILE" \
        --confidence 0.03 \
        --report "$REPORT_KRAKEN2_FILE" \
        --memory-mapping \
        --gzip-compressed "$SAMPLE"
 done
