# Activate the environment
source activate long_read_shotgun
inputdirectory="/media/anegin97/DATA/DATA/Metagenomic/LongShortRead"
# Loop through all the short-read samples for paired-end files
while IFS=, read -r SAMPLE_ID NAME TYPE; do
    # Check if TYPE is "Illumina_shortread"
    if [ "$TYPE" == "Illumina_shortread" ]; then
    # Create the directory for the assembly results
    OUTPUT_DIR="$inputdirectory/short/${SAMPLE_ID}/assembly"
    mkdir -p "$OUTPUT_DIR"
    # define read1 read2
    read1=$(find "$inputdirectory/short" -name "${SAMPLE_ID}*_1.fastq.gz" -print -quit)
    read2=$(find "$inputdirectory/short" -name "${SAMPLE_ID}*_2.fastq.gz" -print -quit)
    # Check if both read files exist
    if [ -z "$read1" ] || [ -z "$read2" ]; then
       echo "Error: Paired-end files not found for sample ${SAMPLE_ID}"
       continue
    fi
    # Run MetaSPAdes with paired-end reads
    metaspades.py --threads 20 -1 "$read1" -2 "$read2" -o "$inputdirectory/short/${SAMPLE_ID}/assembly"

    # Check if the assembly was successful
    if [[ $? -ne 0 ]]; then
            echo "Error: MetaSPAdes failed for sample ${SAMPLE_ID}"
            continue
        fi
    echo "MetaSPAdes assembly completed successfully for sample ${SAMPLE_ID}"
    # Move assembly results to appropriate names and compress files
    mv "${OUTPUT_DIR}/assembly_graph_with_scaffolds.gfa" "${OUTPUT_DIR}/${SAMPLE_ID}.gfa"
    mv "${OUTPUT_DIR}/scaffolds.fasta" "${OUTPUT_DIR}/${SAMPLE_ID}.scaffolds.fasta"
    mv "${OUTPUT_DIR}/contigs.fasta" "${OUTPUT_DIR}/${SAMPLE_ID}.contigs.fasta"
    mv "${OUTPUT_DIR}/spades.log" "${OUTPUT_DIR}/${SAMPLE_ID}.log"

    # Compress the result files
    gzip "${OUTPUT_DIR}/${SAMPLE_ID}.contigs.fasta"
    gzip "${OUTPUT_DIR}/${SAMPLE_ID}.scaffolds.fasta"

     mkdir -p "${OUTPUT_DIR}/qc/contigs"
     mkdir -p "${OUTPUT_DIR}/qc/scaffolds"

     # Run MetaQUAST on the compressed contigs file
     metaquast.py --threads 1 --rna-finding --max-ref-number 0 -l "${SAMPLE_ID}" \
                  "${OUTPUT_DIR}/${SAMPLE_ID}.contigs.fasta.gz" -o "${OUTPUT_DIR}/qc/contigs"

     # Run MetaQUAST on the compressed scaffolds file
     metaquast.py --threads 1 --rna-finding --max-ref-number 0 -l "${SAMPLE_ID}" \
                  "${OUTPUT_DIR}/${SAMPLE_ID}.scaffolds.fasta.gz" -o "${OUTPUT_DIR}/qc/scaffolds"
    fi
done < "$inputdirectory/sample-metadata.csv"
