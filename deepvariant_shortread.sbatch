#!/bin/bash -l
#SBATCH -J calling_variants_shortread
#SBATCH --output=calling_variants_shortread-%j.output
#SBATCH --error=calling_variants_shortread-%j.error
#SBATCH -t 120:00:00
#SBATCH --partition=bmh
#SBATCH --mail-type=ALL
#SBATCH --mail-user=plunarodriguez@ucdavis.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=100G

set -euo pipefail
echo "Starting at: $(date)"

# Variables
BIN_VERSION="1.6.1"

#REF is path to reference genome
REF=/group/gmonroegrp2/chaehee/Pablo/pistachio/genome_sequence/Pvera_Kerman_RefGen_v1.fasta
#READS is path to your alignment .bam file, mine was already filtered and sorted
READS=/group/gmonroegrp2/chaehee/Pablo/UCB1_hybridization/02_whatshap/01_align_reads/R1_B1_C6_S6.filtered.sorted.bam
#OUTDIR is path to the output directory
OUTDIR=/group/gmonroegrp2/chaehee/Pablo/UCB1_hybridization/02_whatshap/02_call_variants

# Use node-local scratch, this was possible for me as my HPC had this directory for tmp files
TMPROOT=/tmp/$USER/deepvariant_${SLURM_JOB_ID:-$$}

# Create directories
mkdir -p ${OUTDIR}
mkdir -p ${TMPROOT}

# Redirect temporary and cache files
export TMPDIR=${TMPROOT}
export APPTAINER_CACHEDIR=${TMPROOT}/apptainer_cache
export XDG_CACHE_HOME=${TMPROOT}/.cache

mkdir -p ${APPTAINER_CACHEDIR}
mkdir -p ${XDG_CACHE_HOME}

# Prepare output names
PRE=$(basename "$READS" .bam)
OUT=${PRE}_deepvariant

# Load module
module load apptainer/latest

echo "Running DeepVariant"
echo "Temporary directory: ${TMPROOT}"

# Run DeepVariant
# the 1st --bind is the path to the directory weer I will store my output files
# the 2nd --bind is for the temporary directory
# the 3rd --bind is to my local 
# the --env selects the temporary directory and the cache
# docker runs deepvariant
# --model_type specifies your data type, in this case it was whole genome sequencing data
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
  --env XDG_CACHE_HOME=${XDG_CACHE_HOME} \
  docker://google/deepvariant:${BIN_VERSION} \
  /opt/deepvariant/bin/run_deepvariant \
    --model_type WGS \
    --ref ${REF} \
    --reads ${READS} \
    --make_examples_extra_args="include_med_dp=true" \
    --output_vcf ${OUTDIR}/${OUT}.vcf.gz \
    --output_gvcf ${OUTDIR}/${OUT}.gvcf.gz \
    --num_shards 4

echo "DeepVariant finished."
echo "Outputs are in: $OUTDIR"
