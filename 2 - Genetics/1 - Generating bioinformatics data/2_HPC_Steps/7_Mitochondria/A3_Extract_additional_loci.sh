#!/bin/bash
#SBATCH --job-name=extract_genes
#SBATCH --output=extract_genes_%j.log
#SBATCH --error=extract_genes_%j.err
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=1G
#SBATCH --account=BISC020282

module load samtools/1.19.2-737f
module load seqtk

cytb_START=16417
cytb_END=17397
ND5_START=19948
ND5_END=21189

BASE_DIR="/user/work/pk14885/Samtools_Mito_results"
header_name="atg000004l_rc_rotated"  # Adjust if different

for climate_zone in ${BASE_DIR}/*; do
    for population in ${climate_zone}/*; do
        for wasp_dir in ${population}/*; do
            wasp=$(basename ${wasp_dir})
            cd ${wasp_dir}

            fasta="${wasp}_consensus_masked.fasta"

            # cytb extraction
            samtools faidx ${fasta} ${header_name}:${cytb_START}-${cytb_END} > ${wasp}_cytb_raw.fasta
            seqtk seq -r ${wasp}_cytb_raw.fasta > ${population##*/}_${wasp}_cytb_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_cytb_output.fasta > cytb_tmp.fasta && mv cytb_tmp.fasta ${population##*/}_${wasp}_cytb_output.fasta

            # ND5 extraction
            samtools faidx ${fasta} ${header_name}:${ND5_START}-${ND5_END} > ${wasp}_ND5_raw.fasta
            seqtk seq -r ${wasp}_ND5_raw.fasta > ${population##*/}_${wasp}_ND5_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_ND5_output.fasta > ND5_tmp.fasta && mv ND5_tmp.fasta ${population##*/}_${wasp}_ND5_output.fasta

        done
    done
done
