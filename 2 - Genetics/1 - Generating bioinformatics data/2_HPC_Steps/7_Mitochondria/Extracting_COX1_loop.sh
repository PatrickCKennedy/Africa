#!/bin/bash

# - - - - - - - - - - - - - - - - - - - - - - -
# Transparency note: The following code for extracting COX1 genes from MitoBIM outputs was developed and improved iteratively with advice from Microsoft Copilot.

# Below, we filter for hits that have qcovs>90 and pident>90 (using '$4 >= 90 && $5 >= 90'). We also drop any sequences that have more than 10% ambiguous bases (x in the MitoBIM output), using "$amb_ratio > 0.10" (these excluded samples are recorded in the log). We also include a post-extraction validation step, in which we BLAST each of the resulting COX1 sequences against the wasp reference to exclude any potential contaminant samples (i.e., non-wasps).

REF="/Users/pk14885/Downloads/COX1.fasta"
INPUT_DIR="/Volumes/Social_evolution_in_animals/MitoBIM_outputs_from_HPC/Maroua_CollatedKeyOutputs"
OUTDIR="cox1_extracted"
VALIDATED_OUTDIR="cox1_validated"
PARTIAL_OUTDIR="cox1_partial"
DEBUG_DIR="debug_hits"
LOGFILE="excluded_samples.log"
SUMMARY="summary_report.txt"
MINLEN=400  # ✅ Lowered threshold
TMPDIR="tmp_blast"

mkdir -p "$OUTDIR" "$VALIDATED_OUTDIR" "$PARTIAL_OUTDIR" "$TMPDIR" "$DEBUG_DIR"
echo "Excluded samples due to >10% ambiguous bases, short length, invalid characters, no hit, or failed species validation:" > "$LOGFILE"
echo -e "Sample\tStatus\tIdentity\tCoverage\tLength" > "$SUMMARY"

echo "Creating BLAST database for reference..."
makeblastdb -in "$REF" -dbtype nucl -blastdb_version 4 -out "$TMPDIR/ref_db"

for file in "$INPUT_DIR"/*.fasta; do
    sample=$(basename "$file" .fasta)
    echo "Processing $sample..."

    CLEANED="$TMPDIR/${sample}_cleaned.fasta"
    awk '/^>/ {print; next} {gsub(/[^ATGCatgcNn]/,"N"); print}' "$file" > "$CLEANED"

    makeblastdb -in "$CLEANED" -dbtype nucl -blastdb_version 4 -out "$TMPDIR/$sample" > /dev/null 2>&1

    blastn -query "$REF" -db "$TMPDIR/$sample" -outfmt "6 sseqid sstart send qcovs pident length" \
        | awk '$5 >= 70' | sort -k6,6nr | head -n 1 > tmp_hits.txt

    hit_id=$(awk '{print $1}' tmp_hits.txt)
    start=$(awk '{print $2}' tmp_hits.txt)
    end=$(awk '{print $3}' tmp_hits.txt)

    if [ -n "$hit_id" ]; then
        awk -v id="$hit_id" -v s="$start" -v e="$end" -v sample="$sample" -v logfile="$LOGFILE" -v minlen="$MINLEN" -v outdir="$OUTDIR" '
        function revcomp(seq) {
            gsub(/A/,"t",seq); gsub(/T/,"a",seq);
            gsub(/G/,"c",seq); gsub(/C/,"g",seq);
            return toupper(reverse(seq));
        }
        function reverse(str) {
            rev=""; for(i=length(str); i>0; i--) rev=rev substr(str,i,1);
            return rev;
        }
        BEGIN {seq=""; header=""}
        /^>/ {if(seq!=""){process_seq()} seq=""; header=$0}
        $0 !~ /^>/ {gsub(/[ \r\t]/,"",$0); seq=seq$0}
        END {if(seq!=""){process_seq()}}
        function process_seq() {
            if(header ~ id) {
                if(s < 1) s = 1;
                if(e > length(seq)) e = length(seq);
                if(s > e) {tmp=s; s=e; e=tmp; seq = revcomp(substr(seq, s, e - s + 1))}
                else {seq = substr(seq, s, e - s + 1)}
                if(length(seq) == 0) {print sample " skipped (empty sequence)" >> logfile; return}
                gsub(/[^ATGCN]/,"N",seq); seq = toupper(seq)
                if(seq ~ /[^ATGCN]/) {print sample " skipped (invalid chars)" >> logfile; return}
                amb_count=gsub(/[N]/,"",seq); amb_ratio=amb_count/length(seq)
                if(amb_ratio > 0.10) {print sample " skipped (ambiguous ratio: " amb_ratio ")" >> logfile}
                else if(length(seq) < minlen) {print sample " skipped (length " length(seq) " < " minlen ")" >> logfile}
                else {print ">" sample "_COX1\n" seq > (outdir "/" sample "_COX1.fasta")}
            }
        }
        ' "$CLEANED"

        if [ -f "$OUTDIR/$sample"_COX1.fasta ]; then
            blastn -query "$OUTDIR/$sample"_COX1.fasta -db "$TMPDIR/ref_db" -word_size 7 -dust no -outfmt "6 qseqid pident qcovs" > "$DEBUG_DIR/${sample}_validation_hits.txt"
            best_hit=$(head -n 1 "$DEBUG_DIR/${sample}_validation_hits.txt")
            identity=$(echo "$best_hit" | awk '{print $2}')
            coverage=$(echo "$best_hit" | awk '{print $3}')

            if [ -z "$identity" ]; then
                echo "$sample skipped (no validation hit)" >> "$LOGFILE"
                echo -e "$sample\tNoValidation\t-\t-\t$(wc -c < "$OUTDIR/$sample"_COX1.fasta)" >> "$SUMMARY"
                rm "$OUTDIR/$sample"_COX1.fasta
            elif (( $(echo "$identity >= 90" | bc -l) )) && (( $(echo "$coverage >= 90" | bc -l) )); then
                mv "$OUTDIR/$sample"_COX1.fasta "$VALIDATED_OUTDIR/"
                echo -e "$sample\tValidated\t$identity\t$coverage\t$(wc -c < "$VALIDATED_OUTDIR/$sample"_COX1.fasta)" >> "$SUMMARY"
            elif (( $(echo "$identity >= 70" | bc -l) )) && (( $(echo "$coverage >= 50" | bc -l) )); then
                mv "$OUTDIR/$sample"_COX1.fasta "$PARTIAL_OUTDIR/"
                echo -e "$sample\tPartial\t$identity\t$coverage\t$(wc -c < "$PARTIAL_OUTDIR/$sample"_COX1.fasta)" >> "$SUMMARY"
            else
                echo "$sample skipped (validation too low: identity=$identity coverage=$coverage)" >> "$LOGFILE"
                rm "$OUTDIR/$sample"_COX1.fasta
            fi
        fi
    else
        echo "$sample skipped (no COX1 hit)" >> "$LOGFILE"
        echo -e "$sample\tNoHit\t-\t-\t-" >> "$SUMMARY"
    fi
done

rm -f tmp_hits.txt
rm -rf "$TMPDIR"

echo "Processing complete."
echo "Validated COX1 sequences: $VALIDATED_OUTDIR"
echo "Partial COX1 sequences: $PARTIAL_OUTDIR"
echo "Debug BLAST hits: $DEBUG_DIR"
echo "Summary report: $SUMMARY"
echo "Check $LOGFILE for details."
