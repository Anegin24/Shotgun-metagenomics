source activate long_read_shotgun
KRAKEN2_DB="/media/anegin97/DATA/DATA/20240917_L879Y_HPVHBSHCV/krakendatabasestandard"
inputdirectory="/media/anegin97/DATA/DATA/Metagenomic/LongShortRead"
find "$inputdirectory/kraken2" -name "*report*" | while read -r SAMPLE; do
SAMPLE_NAME=$(basename "$SAMPLE" .contigs.assembly.kraken2.report.txt)
REPORT_KRAKEN2_FILE="$inputdirectory/kraken2/kraken2_${SAMPLE_NAME}/${SAMPLE_NAME}.contigs.assembly.kraken2.report.txt"
REPORT_MPA_FILE="$inputdirectory/kraken2/kraken2_${SAMPLE_NAME}/${SAMPLE_NAME}.assembly.kraken2.mpa"
python kreport2mpa.py -r "$REPORT_KRAKEN2_FILE" --display-header -o "$REPORT_MPA_FILE"
 for LEVEL in P C O F G S S1; do
        bracken \
            -d "$KRAKEN2_DB" \
            -i "$REPORT_KRAKEN2_FILE" \
            -o $inputdirectory/kraken2/${SAMPLE_NAME}.assembly.bracken_${LEVEL}.txt \
            -r 300 \
            -l "$LEVEL"
    done    
done
for LEVEL in P C O F G S S1; do
    combine_bracken_outputs.py \
        --files $inputdirectory/kraken2/*.assembly.bracken_${LEVEL}.txt \
        --output "$inputdirectory/kraken2/long_short.contigs.bracken_${LEVEL}.txt"
done

MPA_DIR="$inputdirectory/taxonomy_mpa"
mkdir -p "$MPA_DIR"
# Find and copy all .mpa files from subdirectories into the taxonomy_mpa directory
find "$inputdirectory" -type f -name "*.assembly.kraken2.mpa" | xargs cp -n -t "$MPA_DIR" 
# Use -n to avoid overwriting existing files

# Check if there are any MPA files before attempting to combine them
if ls "$MPA_DIR"/*.mpa 1> /dev/null 2>&1; then
    # Combine all MPA files into a single summary output file
    python combine_mpa.py -i "$MPA_DIR"/*.mpa --output "long_short.contigs.kraken.txt"
else
    # Print a message if no MPA files are found
    echo "No .mpa files found in $MPA_DIR. Skipping combination step."
fi

# Remove the MPA_DIR after processing
rm -rf "$MPA_DIR"
