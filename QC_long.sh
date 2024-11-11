#activate the environment
mamba activate long_read_shotgun
#Inputdir
inputdirectory="/media/anegin97/DATA/DATA/Metagenomic/LongShortRead"
#Define host reference genome
hg38="$inputdirectory/hg38.fa"

while IFS=, read -r SAMPLE_ID NAME TYPE; do
    # Check if TYPE is "ONT_longread"
    if [ "$TYPE" == "ONT_longread" ]; then
        # Define the sample path using the SAMPLE_ID
        sample=$(find "$inputdirectory/long" -name "${SAMPLE_ID}*.fastq.gz" -print -quit)
        if [ -n "$sample" ]; then
            echo "Processing $NAME with path $sample"
            # generate folder output
            mkdir -p "$inputdirectory/long/${SAMPLE_ID}/trimmed"
            mkdir -p "$inputdirectory/long/${SAMPLE_ID}/remove_host"
            mkdir -p "$inputdirectory/long/${SAMPLE_ID}/qc"
            # Adapter trimming for Oxford Nanopore reads
            porechop -i "$sample" -t 20 -o "$inputdirectory/long/${SAMPLE_ID}/trimmed/${SAMPLE_ID}.porechop.fastq"
            #aligment with host reference genome
            minimap2 -t 20 -ax map-ont -m 50 --secondary=no $hg38 \
            "$inputdirectory/long/${SAMPLE_ID}/trimmed/${SAMPLE_ID}.porechop.fastq" | samtools sort -@ 20 -o "$inputdirectory/long/${SAMPLE_ID}/${SAMPLE_ID}.sorted.bam"
            # Get unmapped reads & convert sorted BAM to unmapped BAM
            samtools view -@ 20 -b -f 4 \
            -o "$inputdirectory/long/${SAMPLE_ID}/${SAMPLE_ID}.unmapped.bam" \
            "$inputdirectory/long/${SAMPLE_ID}/${SAMPLE_ID}.sorted.bam"
            # Convert unmapped BAM to FASTQ format and compress it
            samtools fastq -@ 20 -T '*' "$inputdirectory/long/${SAMPLE_ID}/${SAMPLE_ID}.unmapped.bam" | bgzip -@ 20 > "$inputdirectory/long/${SAMPLE_ID}/remove_host/${SAMPLE_ID}.rmhost.fastq.gz"
            # Optionally remove the sorted BAM and unmapped BAM files if not needed
            rm "$inputdirectory/long/${SAMPLE_ID}/${SAMPLE_ID}.sorted.bam" "$inputdirectory/long/${SAMPLE_ID}/${SAMPLE_ID}.unmapped.bam"
            cd "$inputdirectory/long/${SAMPLE_ID}/" 
            NanoPlot -t 10 -p filtered -c darkblue --title "${SAMPLE_ID}" --fastq "$inputdirectory/long/${SAMPLE_ID}/remove_host/${SAMPLE_ID}.rmhost.fastq.gz"   
        else
            echo "No file found for SAMPLE_ID $SAMPLE_ID"
        fi
     fi
done < "$inputdirectory/sample-metadata.csv"
