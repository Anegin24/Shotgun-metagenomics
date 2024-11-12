# Shotgun metagenomic workflow (Long&short read)
### 1. Setup
**1.1. Install Miniforge**
Download and install Miniforge (a minimal conda installer):
```bash
wget --no-check-certificate https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh
conda init
source ~/.bashrc
```
**1.2. Install dependencies**
**long_read_shotgun environment**
```bash
# Create a new environment named bio-env
mamba create --name long_read_shotgun -y

# Activate the environment
source activate long_read_shotgun

# Install packages from Bioconda
mamba install -c bioconda sra-tools
mamba install -c bioconda fastp porechop bowtie2 samtools minimap2 fastqc nanoplot quast spades flye pandas kraken2 bracken
```
**Set up the environment for binning.**
```bash
mamba create --name binning python=2.7.15 \
    metawrap \
    biopython=1.68 \
    blast=2.6.0 \
    bmtagger=3.101 \
    bowtie2=2.3.5 \
    bwa=0.7.17 \
    checkm-genome=1.0.12 \
    fastqc=0.11.8 \
    kraken=1.1 \
    kraken2=2.0 \
    krona=2.7 \
    matplotlib-base=2.2.3 \
    maxbin2=2.2.6 \
    metabat2=2.12.1 \
    pandas=0.24.2 \
    perl-bioperl \
    pplacer=1.1.alpha19 \
    prokka=1 \
    quast=5.0.2 \
    r-ggplot2=3.1.0 \
    r-reshape2 \
    r-recommended=3.5.1 \
    samtools=1.9 \
    seaborn=0.9.0 \
    spades=3.13.0 \
    trim-galore=0.5.0
```
**Set up the environment for checkm**
```bash
# Create and activate the conda environment
mamba create -n checkm2 python=3.8 -y
mamba activate checkm2

# Install CheckM2
mamba install -c bioconda checkm2 -y

# Create directory for CheckM2 database
mkdir -p checkm2_db
cd checkm2_db

# Download the CheckM2 database
checkm2 database --download --path .

# Set the CHECKM2DB environment variable
export CHECKM2DB="path/to/checkm2_db"
```
### 2. Download Dataset
**Generate SraAccList.txt**
```bash
SRR18491298
SRR18491084
SRR18491050
SRR18490941
SRR18490946
SRR18491056
SRR18491085
SRR18490950
SRR18491259
SRR18490980
SRR18491247
SRR18490968
SRR18491039
SRR18491329
SRR18490989
SRR18491307
SRR18491312
SRR18490994
SRR18491000
SRR18491318
SRR18491323
SRR18491005
SRR18491040
SRR18491330
SRR18491337
SRR18491047
```
**Generate sample-metadata.csv**
```bash
Sample-id	name	type
SRR18490938	TD78	Illumina_shortread
SRR18490939	CD35	Illumina_shortread
SRR18490940	TD40	ONT_longread
SRR18490941	TD39	ONT_longread
SRR18490946	TD34	ONT_longread
SRR18490950	CD34	Illumina_shortread
SRR18490968	CD90	ONT_longread
SRR18490980	CD79	ONT_longread
SRR18490989	TD70	Illumina_shortread
SRR18490994	TD65	Illumina_shortread
SRR18491000	TD60	Illumina_shortread
SRR18491005	TD55	Illumina_shortread
SRR18491039	TD50	Illumina_shortread
SRR18491040	TD49	Illumina_shortread
SRR18491047	TD42	Illumina_shortread
SRR18491050	TD40	Illumina_shortread
SRR18491056	TD34	Illumina_shortread
SRR18491084	CD35	ONT_longread
SRR18491085	CD34	ONT_longread
SRR18491247	CD90	Illumina_shortread
SRR18491259	CD79	Illumina_shortread
SRR18491298	TD78	ONT_longread
SRR18491307	TD70	ONT_longread
SRR18491312	TD65	ONT_longread
SRR18491318	TD60	ONT_longread
SRR18491323	TD55	ONT_longread
SRR18491329	TD50	ONT_longread
SRR18491330	TD49	ONT_longread
SRR18491337	TD42	ONT_longread
SRR18491051	TD39	Illumina_shortread
```
**Download raw data**
```bash
prefetch --option-file SraAccList.txt
```
**Moving data & generate fastq**
```bash
#!/bin/bash
inputdirectory="/media/anegin97/DATA/DATA/Metagenomic/LongShortRead/"
# Create the target directories
mkdir -p "$inputdirectory/long/fastqlong" "$inputdirectory/short/fastqshort"
# Loop through each line in the CSV file
while IFS=',' read -r sample_id name type; do
    # Skip the header row
    if [[ $sample_id == "Sample-id" ]]; then
        continue
    fi

    # Determine the target directory based on type
    if [[ $type == "ONT_longread" ]]; then
        target_dir="long"
    elif [[ $type == "Illumina_shortread" ]]; then
        target_dir="short"
    else
        continue
    fi

    # Move the folder
    folder_path="./$sample_id"  # Assuming folders are named by Sample-id
    if [[ -d $folder_path ]]; then
        mv "$folder_path" "$inputdirectory/$target_dir/"
        echo "Moved folder $folder_path to $inputdirectory/$target_dir"
    else
        echo "Folder $folder_path not found"
    fi

    # Process with fastq-dump after moving the folder
    if [[ $type == "ONT_longread" ]]; then
        fastq-dump --gzip "$inputdirectory/$target_dir/$sample_id/*" -O "$inputdirectory/long/fastqlong"
    elif [[ $type == "Illumina_shortread" ]]; then
        fastq-dump --split-files --gzip "$inputdirectory/$target_dir/$sample_id/*" -O "$inputdirectory/short/fastqshort"
    fi
done < sample-metadata.csv
```
### 3. Download Database
**3.1. Human genome reference**
**Download fasta**
```bash
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz
gunzip hg38.fa.gz
```
**Indexing bowtie2**
```bash
# Activate the environment
source activate long_read_shotgun

mkdir host_index
cd host_index
bowtie2-build --threads 20 ../hg38.fa "bt2_index_base"
```
**3.2. Taxonomic Classification**

**Download Kraken-Standard**
```bash
https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20240904.tar.gz
tar -xzvf k2_standard_20240904.tar.gz k2_standard
```
## 4. Shotgun Metagenomics Workflow
**4.1. Quality Control**

**For short read**
```
bash QC_short.sh
```
**For long read**
```bash
QC_long.sh
```
