#!/bin/bash
#SBATCH --job-name=Calculating_base_frequencies_once
#SBATCH --cpus-per-task=16
#SBATCH --mem=8G
#SBATCH --time=2:00:00
#SBATCH --mail-user=pk14885@bristol.ac.uk
#SBATCH --account=BISC020282

# If running distANGSD in GTR mode, we need to supply the 9 GTR parameters using the -par function.
# To provide the equilibrium base frequencies, we use the relative frequencies in the reference genome.
# This script takes the reference genome, and calculates the frequencies of the 4 bases. It only needs
# to be run once.

set -euo pipefail

REF="ref.fa"

# Stream sequence lines (exclude headers), remove whitespace, uppercase, and count bases
grep -v '^>' "$REF" \
| tr -d ' \t\r' \
| tr 'a-z' 'A-Z' \
| awk '
BEGIN{A=0;C=0;G=0;T=0}
{
  gsub(/[^ACGT]/,"");    # drops anything that is not A, C, G, or T (such as gaps or N)
  for(i=1;i<=length($0);i++){    # loops through each base
    b=substr($0,i,1);      #  'substr' (substring) here extracts the character at position i from line $0 of size 1 (i.e., one character)
    if(b=="A") A++;    # if the character is an A, increment the variable 'A' by one (which tracks the number of A bases).
    else if(b=="C") C++; 
    else if(b=="G") G++; 
    else if(b=="T") T++;
  }
}
END{
  total=A+C+G+T; if(total==0){total=1}
  printf("Counts  : A=%d C=%d G=%d T=%d\n",A,C,G,T);
  printf("Frequencies (π): A=%.6f C=%.6f G=%.6f T=%.6f\n",A/total,C/total,G/total,T/total);
  printf("PAR tail (π_A,π_C,π_G,π_T): %.6f,%.6f,%.6f,%.6f\n",A/total,C/total,G/total,T/total);
}'

# RESULT (4th Jan 2026):
# The results of running this on the B. juncea reference genome are:
##Counts  : A=108203811 C=50762085 G=50428228 T=106323679
##Frequencies (π): A=0.342723 C=0.160783 G=0.159726 T=0.336768
##PAR tail (π_A,π_C,π_G,π_T): 0.342723,0.160783,0.159726,0.336768
