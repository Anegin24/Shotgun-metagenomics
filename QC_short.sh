#activate the environment
mamba activate long_read_shotgun
#Inputdir
inputdirectory="/media/anegin97/DATA/DATA/Metagenomic/LongShortRead"
#Define host reference genome
hg38="$inputdirectory/hg38.fa"

while IFS=, read -r SAMPLE_ID NAME TYPE; do
    # Check if TYPE is "Illumina_shortread"
    if [ "$TYPE" == "Illumina_shortread" ]; then
        # Define the sample path using the SAMPLE_ID
        read1=$(find "$inputdirectory/short" -name "${SAMPLE_ID}*_1.fastq.gz" -print -quit)
        read2=$(find "$inputdirectory/short" -name "${SAMPLE_ID}*_2.fastq.gz" -print -quit)
        if [ -n "$read1" ] && [ -n "$read2" ]; then
            echo "Processing $NAME with data input $read1 & $read2"
            # generate folder output
            mkdir -p "$inputdirectory/short/${SAMPLE_ID}/trimmed"
            mkdir -p "$inputdirectory/short/${SAMPLE_ID}/remove_host"
            mkdir -p "$inputdirectory/short/${SAMPLE_ID}/fastqc"
            # Adapter trimming for Illumina short reads
            fastp \
        	--in1 "$read1" \
		--in2 "$read2" \
		--out1 "$inputdirectory/short/${SAMPLE_ID}/trimmed/${SAMPLE_ID}_1.fastp.fastq.gz" \
		--out2 "$inputdirectory/short/${SAMPLE_ID}/trimmed/${SAMPLE_ID}_2.fastp.fastq.gz" \
		--json "$inputdirectory/short/${SAMPLE_ID}/trimmed/${SAMPLE_ID}_fastp.fastp.json" \
		--html "$inputdirectory/short/${SAMPLE_ID}/trimmed/${SAMPLE_ID}_fastp.fastp.html" \
		--thread 20 \
		--detect_adapter_for_pe \
		-q 15 --cut_front --cut_tail --cut_mean_quality 15 --length_required 15 \
        	2> "$inputdirectory/short/${SAMPLE_ID}/trimmed/${SAMPLE_ID}_fastp.fastp.log"
            #bowtie2 aligment with host reference genome
	    bowtie2 -p 20 \
		-x "$inputdirectory/hg38" \
		-1 "$inputdirectory/short/${SAMPLE_ID}/trimmed/${SAMPLE_ID}_1.fastp.fastq.gz" \
		-2 "$inputdirectory/short/${SAMPLE_ID}/trimmed/${SAMPLE_ID}_2.fastp.fastq.gz" \
		--sensitive \
		--un-conc-gz "$inputdirectory/short/${SAMPLE_ID}/remove_host/${SAMPLE_ID}_host_removed.unmapped_%.fastq.gz" \
		--al-conc-gz "$inputdirectory/short/${SAMPLE_ID}/remove_host/${SAMPLE_ID}_host_removed.mapped_%.fastq.gz" \
		1> /dev/null \
		2> "$inputdirectory/short/${SAMPLE_ID}/remove_host/${SAMPLE_ID}_host_removed.bowtie2.log"
            #remove mapped
            rm -f "$inputdirectory/short/${SAMPLE_ID}/remove_host/${SAMPLE_ID}_host_removed.mapped_*.fastq.gz"
            #FastQC
            fastqc \
		--quiet \
		--threads 6 \
		--memory 10000 \
		-o "$inputdirectory/short/${SAMPLE_ID}/fastqc" \
		"$inputdirectory/short/${SAMPLE_ID}/remove_host/${SAMPLE_ID}_host_removed.unmapped_1.fastq.gz" \
		"$inputdirectory/short/${SAMPLE_ID}/remove_host/${SAMPLE_ID}_host_removed.unmapped_2.fastq.gz"
        else
            echo "No file found for SAMPLE_ID $SAMPLE_ID"
        fi
     fi
done < "$inputdirectory/sample-metadata.csv"
mkdir -p "$inputdirectory/short/multiqc_report"
find "$inputdirectory/short" -name "*fastqc*.zip" -o -name "*fastqc*.html" | xargs multiqc -o "$inputdirectory/short/multiqc_report"
