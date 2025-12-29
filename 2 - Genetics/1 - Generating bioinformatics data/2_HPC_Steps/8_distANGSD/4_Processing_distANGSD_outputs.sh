# Once the array job in script 3 has completed, all the separate pairwise genetic distances (t values) will be
# in the results folder, each in their own .tsv files. First, concatenate them together:

(echo -e "A\tB\tOUTPFX\tmodel\tmethod\tt\tp_inv"; \
  awk 'FNR==1 && NR>1 {next} {print}' results/distances.*.tsv) > results/distances.all.tsv
