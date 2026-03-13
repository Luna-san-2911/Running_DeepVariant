#!/bin/bash -l
#SBATCH -J calling_variants_shortread_loop
#SBATCH --output=calling_variants_shortread_loop-%j.output
#SBATCH --error=calling_variants_shortread_loop-%j.error
#SBATCH -t 336:00:00
#SBATCH --partition=bmh
#SBATCH --mail-type=ALL
#SBATCH --mail-user=plunarodriguez@ucdavis.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=150G

set -euo pipefail
echo "Starting at: $(date)"

#DeepVariant Version
BIN_VERSION="1.6.1"

# Directories
#REF is path to reference genome
#READS is path to your alignment .bam file, mine was already filtered and sorted
#OUTDIR is path to the output directory

BAM_DIR=/group/gmonroegrp2/chaehee/Pablo/pangenie/05_map_sample_to_infered_haplotype/01_align
REF_DIR=/group/gmonroegrp2/chaehee/Pablo/pangenie/03_infered_haplotypes/output
OUTDIR=/group/gmonroegrp2/chaehee/Pablo/pangenie/05_map_sample_to_infered_haplotype/02_call_variants

# Use node-local scratch, this was possible for me as my HPC had this directory for tmp files
TMPROOT=${OUTDIR}/tmp

# Create required directories
mkdir -p ${OUTDIR}
mkdir -p ${TMPROOT}

# Redirect all caches and temporary files
export TMPDIR=${TMPROOT}
export APPTAINER_CACHEDIR=${TMPROOT}/apptainer_cache
export XDG_CACHE_HOME=${TMPROOT}/.cache
export HOME=${TMPROOT}/fake_home

mkdir -p ${APPTAINER_CACHEDIR}
mkdir -p ${XDG_CACHE_HOME}
mkdir -p ${HOME}

# Load modules
module load apptainer
module load samtools

echo "Temporary files will be stored in ${TMPROOT}"

# Loop through BAM files
for READS in ${BAM_DIR}/*_filtered_sorted.bam
do

    SAMPLE=$(basename "$READS" | sed 's/_filtered_sorted.bam//')

    REF=${REF_DIR}/${SAMPLE}_1_pangenie_hap1.fasta
    OUT=${SAMPLE}_deepvariant

    if [[ ! -f ${REF} ]]; then
        echo "Reference ${REF} not found for ${SAMPLE}, skipping."
        continue
    fi

    # Create FASTA index if missing
    if [[ ! -f ${REF}.fai ]]; then
        echo "Indexing reference for ${SAMPLE}"
        samtools faidx ${REF}
    fi

    echo "Running DeepVariant for ${SAMPLE}"

# Run DeepVariant
# the 1st --bind is the path to the directory weer I will store my output files
# the 2nd --bind is for the temporary directory
# the 3rd --bind is to my local 
# the --env selects the temporary directory and the cache
# docker runs deepvariant
# --model_type specifies your data type, in this case it was whole-genome-sequencing short-read
# --ref is the path to the reference genome
# --reads is the path to the .bam file
# --make_examples_extra_args includes mean depth as output data
# --output_vcf and --output-gvcf specify the path to the output vcf and gvcf files, they could be gzipped
# num_shards specifies the number of cores or CPU to use

    apptainer exec \
      --bind /group/gmonroegrp2:/group/gmonroegrp2 \
      --bind ${TMPROOT}:${TMPROOT} \
      --bind /usr/lib/locale \
      --env TMPDIR=${TMPDIR} \
      --env HOME=${HOME} \
      --env XDG_CACHE_HOME=${XDG_CACHE_HOME} \
      docker://google/deepvariant:${BIN_VERSION} \
      /opt/deepvariant/bin/run_deepvariant \
        --model_type WGS \
        --ref ${REF} \
        --reads ${READS} \
        --make_examples_extra_args="include_med_dp=true" \
        --output_vcf ${OUTDIR}/${OUT}.vcf.gz \
        --output_gvcf ${OUTDIR}/${OUT}.gvcf.gz \
        --num_shards 64

done

echo "DeepVariant finished. Outputs are in $OUTDIR"


