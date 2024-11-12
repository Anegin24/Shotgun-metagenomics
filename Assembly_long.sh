# Activate the environment
source activate long_read_shotgun
#Inputdir
inputdirectory="/media/anegin97/DATA/DATA/Metagenomic/LongShortRead"


while IFS=, read -r SAMPLE_ID NAME TYPE; do
    # Check if TYPE is "ONT_longread"
    if [ "$TYPE" == "ONT_longread" ]; then
    # Create the directory for the assembly results
    mkdir -p "$inputdirectory/long/${SAMPLE_ID}/assembly"
    # Run Flye with the specified parameters
    flye --nano-raw "$inputdirectory/long/${SAMPLE_ID}/remove_host/${SAMPLE_ID}.rmhost.fastq.gz" --out-dir "$inputdirectory/long/${SAMPLE_ID}/assembly" -i 10 -- meta --threads 20

    # Rename the assembly output file
    mv "$inputdirectory/long/${SAMPLE_ID}/assembly/assembly.fasta" "$inputdirectory/long/${SAMPLE_ID}/assembly/${SAMPLE_ID}.contigs.fasta"

    # Compress the contigs file
    bgzip "$inputdirectory/long/${SAMPLE_ID}/assembly/${SAMPLE_ID}.contigs.fasta"

    # Run MetaQUAST on the compressed contigs file
    metaquast.py --threads 20 --rna-finding --max-ref-number 0 -l "${SAMPLE_ID}" "$inputdirectory/long/${SAMPLE_ID}/assembly/${SAMPLE_ID}.contigs.fasta.gz" -o  "$inputdirectory/long/${SAMPLE_ID}/assembly/qc"
fi
done < $inputdirectory/sample-metadata.csv
