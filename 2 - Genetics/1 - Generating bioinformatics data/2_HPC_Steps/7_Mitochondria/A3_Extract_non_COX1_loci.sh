#!/bin/bash
#SBATCH --job-name=extract_genes
#SBATCH --output=extract_genes_%j.log
#SBATCH --error=extract_genes_%j.err
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=1G
#SBATCH --account=BISC020282

module load samtools/1.19.2-737f
module load seqtk

# The previous script (A2) conducted mapping to the reference mitogenome. It produces a (masked where necessary) mitogenome 
# for each wasp. From this, it extracted COX1 (and printed average depth over the COX1 locus as a quality control measure). 
# In this script, we use the mitogenome file for each wasp similarly to extract other loci.

# Here are the start and end positions for the relevant genes from the UCL reference mitogenome ('final_mitogenome.gb').
cytb_START=16417
cytb_END=17397

ND5_START=19948
ND5_END=21189

COX2_START=2707
COX2_END=3354

ND4_START=18626
ND4_END=19837

ND2_START=5218
ND2_END=6165

ATP6_START=1656
ATP6_END=2318

rrnL_START=13992
rrnL_END=15196

BASE_DIR="/user/work/pk14885/Samtools_Mito_results"
header_name="atg000004l_rc_rotated"

for climate_zone in ${BASE_DIR}/*; do
    for population in ${climate_zone}/*; do
        for wasp_dir in ${population}/*; do
            wasp=$(basename ${wasp_dir})
            cd ${wasp_dir}

            fasta="${wasp}_consensus_masked.fasta"

            # Extracting cytb from the mapped mitogenome:
            samtools faidx ${fasta} ${header_name}:${cytb_START}-${cytb_END} > ${wasp}_cytb_raw.fasta
            seqtk seq -r ${wasp}_cytb_raw.fasta > ${population##*/}_${wasp}_cytb_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_cytb_output.fasta > cytb_tmp.fasta && mv cytb_tmp.fasta ${population##*/}_${wasp}_cytb_output.fasta

            # Extracting ND5 from the mapped mitogenome:
            samtools faidx ${fasta} ${header_name}:${ND5_START}-${ND5_END} > ${wasp}_ND5_raw.fasta
            seqtk seq -r ${wasp}_ND5_raw.fasta > ${population##*/}_${wasp}_ND5_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_ND5_output.fasta > ND5_tmp.fasta && mv ND5_tmp.fasta ${population##*/}_${wasp}_ND5_output.fasta

            # Extracting COX2 from the mapped mitogenome:
            samtools faidx ${fasta} ${header_name}:${COX2_START}-${COX2_END} > ${wasp}_COX2_raw.fasta
            seqtk seq -r ${wasp}_COX2_raw.fasta > ${population##*/}_${wasp}_COX2_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_COX2_output.fasta > COX2_tmp.fasta && mv COX2_tmp.fasta ${population##*/}_${wasp}_COX2_output.fasta

            # Extracting ND4 from the mapped mitogenome:
            samtools faidx ${fasta} ${header_name}:${ND4_START}-${ND4_END} > ${wasp}_ND4_raw.fasta
            seqtk seq -r ${wasp}_ND4_raw.fasta > ${population##*/}_${wasp}_ND4_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_ND4_output.fasta > ND4_tmp.fasta && mv ND4_tmp.fasta ${population##*/}_${wasp}_ND4_output.fasta

            # Extracting ND2 from the mapped mitogenome:
            samtools faidx ${fasta} ${header_name}:${ND2_START}-${ND2_END} > ${wasp}_ND2_raw.fasta
            seqtk seq -r ${wasp}_ND2_raw.fasta > ${population##*/}_${wasp}_ND2_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_ND2_output.fasta > ND2_tmp.fasta && mv ND2_tmp.fasta ${population##*/}_${wasp}_ND2_output.fasta

            # Extracting ATP6 from the mapped mitogenome:
            samtools faidx ${fasta} ${header_name}:${ATP6_START}-${ATP6_END} > ${wasp}_ATP6_raw.fasta
            seqtk seq -r ${wasp}_ATP6_raw.fasta > ${population##*/}_${wasp}_ATP6_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_ATP6_output.fasta > ATP6_tmp.fasta && mv ATP6_tmp.fasta ${population##*/}_${wasp}_ATP6_output.fasta

            # Extracting rrnL (which is the 16S rRNA) from the mapped mitogenome:
            samtools faidx ${fasta} ${header_name}:${rrnL_START}-${rrnL_END} > ${wasp}_rrnL_raw.fasta
            seqtk seq -r ${wasp}_rrnL_raw.fasta > ${population##*/}_${wasp}_rrnL_output.fasta
            awk -v header="${population##*/}_${wasp}" 'NR==1{$0=">"header}1' ${population##*/}_${wasp}_rrnL_output.fasta > rrnL_tmp.fasta && mv rrnL_tmp.fasta ${population##*/}_${wasp}_rrnL_output.fasta

        done
    done
done
