#!/bin/bash -l
#SBATCH -J calling_variants_longread
#SBATCH --output=calling_variants_longread-%j.output
#SBATCH --error=calling_variants_longread-%j.error
#SBATCH -t 120:00:00
#SBATCH --partition=bmh
#SBATCH --mail-type=ALL
#SBATCH --mail-user=plunarodriguez@ucdavis.edu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=250G

set -euo pipefail
echo "Starting at: $(date)"

# Variables
BIN_VERSION="1.6.1"  # DeepVariant version
REF=/group/gmonroegrp2/chaehee/Pablo/pistachio/genome_sequence/Pvera_Kerman_RefGen_v1.fasta  # Reference FASTA
READS=/group/gmonroegrp2/chaehee/Pablo/UCB1_hybridization/02_whatshap/01_align_reads/Patl.filtered.sorted.bam  # Input BAM, I already filtered and sorted it. I did the alignment with minimap2
OUTDIR=/group/gmonroegrp2/chaehee/Pablo/UCB1_hybridization/02_whatshap/02_call_variants  # Output directory

# Prepare output
PRE=$(basename "$READS" | sed 's/.bam//')  # Remove .bam for prefix
OUT=${PRE}_deepvariant

# Load module
module load apptainer

# Run DeepVariant
# Same notes as for deepvariant_shortread.sbatch, however, I set a limit of 300 at max_reads_per_partition so that I do not overconsume RAM
# In model_type as I am analyzing PACBIO HiFi long reads, I specify PACBIO
# I reduced shards to 1 as I had long reads with a really hight sequencing depth and it required a lot of RAM

singularity exec \
  --bind /group/gmonroegrp2:/group/gmonroegrp2 \
  --bind /usr/lib/locale/ \
  docker://google/deepvariant:${BIN_VERSION} \
  /opt/deepvariant/bin/run_deepvariant \
    --model_type PACBIO \
    --ref ${REF} \
    --reads ${READS} \
    --make_examples_extra_args="include_med_dp=true,max_reads_per_partition=300" \
    --output_vcf ${OUTDIR}/${OUT}.vcf.gz \
    --output_gvcf ${OUTDIR}/${OUT}.gvcf.gz \
    --num_shards 1

echo "DeepVariant finished. Outputs are in $OUTDIR"
