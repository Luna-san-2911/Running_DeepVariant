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
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail
echo "Starting at: $(date)"

# Variables
BIN_VERSION="1.6.1"  # DeepVariant version
REF=/group/gmonroegrp2/chaehee/Pablo/pistachio/genome_sequence/Pvera_Kerman_RefGen_v1.fasta  # Reference FASTA
READS=/group/gmonroegrp2/chaehee/Pablo/UCB1_hybridization/02_whatshap/01_align_reads/R1_B1_C6_S6.filtered.sorted.bam  # Input BAM
OUTDIR=/group/gmonroegrp2/chaehee/Pablo/UCB1_hybridization/02_whatshap/02_call_variants  # Output directory

# Prepare output
PRE=$(basename "$READS" | sed 's/.bam//')  # Remove .bam for prefix
OUT=${PRE}_deepvariant

# Load module
module load apptainer

# Run DeepVariant

singularity exec \
  --bind /group/gmonroegrp2:/group/gmonroegrp2 \
  --bind /usr/lib/locale/ \
  docker://google/deepvariant:${BIN_VERSION} \
  /opt/deepvariant/bin/run_deepvariant \
    --model_type WGS \
    --ref ${REF} \
    --reads ${READS} \
    --make_examples_extra_args="include_med_dp=true" \
    --output_vcf ${OUTDIR}/${OUT}.vcf.gz \
    --output_gvcf ${OUTDIR}/${OUT}.gvcf.gz \
    --num_shards 8

echo "DeepVariant finished. Outputs are in $OUTDIR"
