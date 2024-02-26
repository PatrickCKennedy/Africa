# PK (local computer R script)
# In this script, we correlate the PC scores of each genomic window with the whole-genome PC scores. To run it, you
# must already have completed '2_PCANGSD_in_genomic_windows.sh' on HPC. 

# This script extensively uses and adapts various parts of the R scripts provided by Merot et al. (2011) in their PCANGSD analysis pipeline. We therefore
# cite Merot et al. (2011) as the source of this analysis.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Adapted from scripts in Merot et al. (2021) pipeline:
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# -------------------------------------------------------------------------------
# SECTION TO RUN IN BASH IN THE TERMINAL:

# To run the commands below, you must first download the relevant files from BluePebble:

        # (1) Remove the '04_pca' and '10_pca_by_window' folders in the local computer Downloads if they exist from a previous run:
                cd Downloads
                rm -r 04_pca
                rm -r 10_pca_by_window 
        
        # (2) Download the covariance matrix for the whole-genome PCA:
                scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together/04_pca 04_pca
        
        # (3) Download the many covariances matrices for the genome-window PCAs:
                cd Downloads
                rm -r 1000
                mkdir 1000
                cd 1000
                scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together/10_pca_by_window/all_maf0.05_pctind0.5_maxdepth20/1000/cov_by_window  cov_by_window 
                scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_both_countries_together/10_pca_by_window/all_maf0.05_pctind0.5_maxdepth20/1000/analyse_by_window  analyse_by_window

# -------------------------------------------------------------------------------
# The rest of this script is for R.
# -------------------------------------------------------------------------------
# FIRST, RUNNING PCA ON THE WHOLE-GENOME COV FILE:
# following https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/Rscripts/make_pca_simple.r
# This section just essentially repeats the analysis that we have already run in the script '1_Analysing PCANGSD results in R.R'
# However, we need to import the data to this script in order to construct the correlation plots with the windows later on in the script.

# Set the working directory to the folder '04_pca', which contains the whole-genome PCA covariance file:
        setwd("/Users/pk14885/Downloads/04_pca")

# Import the right covariance file and call it 'cov_mat':
        cov_mat<-as.matrix(read.table("all_maf0.05_pctind0.5_maxdepth20.cov"), header=F)

# Eigendecomposition to find the PCA:
        pca<-eigen(cov_mat)
        pca.mat<-as.matrix(pca$vectors %*% (diag(pca$values))^0.5)

# Add titles to the columsn of the 'pca.mat' matrix:
        nPC<-dim(pca$vectors)[2]
        col_PC<-vector(length=nPC)
        for (i in 1 : nPC) {col_PC[i]<-paste0("PC",i)}
        colnames(pca.mat)<-c(col_PC)

#add rownames
#bam_names<-read.table(BAM,header=F)
#rownames(pca.mat)<-bam_names$V1

# Calculate how much variance is explained by each principal component:
        var1<-round(pca$values[1]*100/sum(pca$values[pca$values>=0]),2)
        var2<-round(pca$values[2]*100/sum(pca$values[pca$values>=0]),2)
        var3<-round(pca$values[3]*100/sum(pca$values[pca$values>=0]),2)
        var4<-round(pca$values[4]*100/sum(pca$values[pca$values>=0]),2)

#make kmeans for 3 groups on PC1
#kmeans_res<-kmeans(as.matrix(pca.mat[,1]), c(min(pca.mat[,1]), median(pca.mat[,1]), max(pca.mat[,1])))
#k_ss<-round(kmeans_res$betweenss/kmeans_res$totss,3)

# Plot the first two components of the PCA:
        plot(pca.mat[,1], pca.mat[,2], pch=20, ylab=paste("PC2", var2), xlab=paste("PC1", var1))

# Save the whole-genome PCA matrix (keeping the first four components) with the name 'info_pc' (we will use it below):
        info_pc <- pca.mat[,1:4]

# -------------------------------------------------------------------------------
# NOW RUN PCA ON THE LOCAL WINDOWS OF THE GENOME:

# Set the working directory to the folder containing the downloaded window data:
setwd("/Users/pk14885/Downloads/1000")

# Load the 'lostruct' library (note: "If you use this method, please cite Li & Ralph 2019" [https://github.com/petrelharp/local_pca])
      library(lostruct)

# Make sure the correct input values from the ANGSD run are specified here:
        MIN_MAF = 0.05
        PERCENT_IND = 0.5
        WINDOW_SIZE = 1000
        MAX_DEPTH_FACTOR = 20
        N_ind = 108
        N_PC = 2
        N_MDS = 50

# Import the text file containing the list of analysed windows:
      window<-read.table(("analyse_by_window/list_window.txt"),header=F)
      colnames(window)<-"file_name"
      View(window)

# Set up an empty table in which we will record the key information (e.g., start and stop position) of each window:
      window$LG<-vector(length=dim(window)[1])
      window$pos<-vector(length=dim(window)[1])
      window$n_snp<-vector(length=dim(window)[1])
      window$start<-vector(length=dim(window)[1])
      window$stop<-vector(length=dim(window)[1])

# Now fill in the details in that table:
      for (i in 1:dim(window)[1] )
      {
        window$LG[i]<-unlist(strsplit(as.character(window$file_name[i]), split="_"))[3]
        window$pos[i]<-unlist(strsplit(as.character(window$file_name[i]), split="_"))[4]
        window$n_snp[i]<-as.numeric(unlist(strsplit(as.character(window$file_name[i]), split="_"))[5])
        window$start[i]<-as.numeric(unlist(strsplit(as.character(window$pos[i]), split="-"))[1])
        window$stop[i]<-as.numeric(unlist(strsplit(as.character(window$pos[i]), split="-"))[2])
      }

# P: Remove the 'arg' files (we only want the 'cov' files):
      window[- grep("arg", window$file_name),] -> window

# Re-order the windows:
      window_order<-window[order(window$LG, window$start),]
      View(window)

# Running 'lostruct' on each window:
      
      # "prepare an empty matrix with nrow= nb of window, and ncol= sumofsquares + nb of eigen value + dim of all eigen vectors (Nb individuals * N_Pc)" (Moret et al., 2021)
                window_eigs<-matrix(nrow=dim(window_order)[1], ncol= (1+N_PC+ (N_ind*N_PC)))
      
      # Eigendecomposition on each window's covariance file:
                for (i in 1: dim(window_order)[1])
                {
                  print(paste("import covariance matrix for window and get eigenvectors",i))
                  window_covmats_i<-as.matrix(read.table(paste0("cov_by_window/",window_order$file_name[i])))
                  window_eigs [i,]<- cov_pca(k=N_PC, covmat=window_covmats_i)
                }

      # "run lostruct fonctions to calculate  distances between pca made on each window":
                print(paste("calculating distance between window PCA with NPC=",N_PC))
                window_dist<- pc_dist(window_eigs, npc=N_PC)

      # "run a MDS to visualise the distribution of window"
              print(paste("run MDS on distance matrix and will keep N_MDS=",N_MDS))
              mds_axe<-cmdscale(window_dist, eig=TRUE, k=N_MDS)
              window_order_mds<-cbind(window_order, mds_axe$points)

# Plot the different MDS axes:
              print("plotting MDS axis")
              plot(mds_axe$points[,1], mds_axe$points[,2], pch=20)
              plot(mds_axe$points[,3], mds_axe$points[,4], pch=20)
              plot(mds_axe$points[,5], mds_axe$points[,6], pch=20)
              plot(mds_axe$points[,7], mds_axe$points[,8], pch=20)
              plot(mds_axe$points[,9], mds_axe$points[,10], pch=20)
              plot(mds_axe$points[,11], mds_axe$points[,12], pch=20)

# Calculate the correlation between each local-window's PCs and the full whole-genome PCA, "to see which portions of the genome are associated
# with the structure seen on the first 3 PCs of the PCa on the whole genome":
            for (i in 1: dim(window_order)[1])
            {
              print(paste("calculating corr pca for window",i))
              PC_mat_i<- t(rbind(window_eigs[i,4:(3+N_ind)],window_eigs[i,(4+N_ind):(3+2*N_ind)]))
              window_order$eig_pc1[i]<-window_eigs[i,1] #not sure which number is eigenvalue or sum of square and how to get variance from there
              window_order$eig_pc2[i]<-window_eigs[i,2]
              window_order$corr_pc1[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,1])$estimate)
              window_order$corr_pc2[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,2])$estimate)
              window_order$corr_pc3[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,3])$estimate)
              window_order$corr_pc4[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,4])$estimate)
              #window_order$corr_pc5[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,5])$estimate)
              #window_order$corr_pc6[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,6])$estimate)
              #window_order$corr_pc7[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,7])$estimate)
              #window_order$corr_pc8[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,8])$estimate)
              #window_order$corr_pc9[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,9])$estimate)
              #window_order$corr_pc10[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,10])$estimate)
              #window_order$corr_pc11[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,11])$estimate)
              #window_order$corr_pc12[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,12])$estimate)
            }
write.table(window_order,paste0("analyse_by_window/window_corr_pc_all_LG.txt"), quote=F,row.names=F)  

# P: Focus on the 20 largest scaffolds and make a ggplot:
            window_order$LG <- as.numeric(window_order$LG)
            data_for_20_largest_scaffolds = subset(window_order,window_order$LG<21)
            corrPC1_plot <- ggplot(data=data_for_20_largest_scaffolds, aes(x=start/1000000,y=corr_pc1)) +
                                      geom_point(colour='black', size = 0.5, alpha = 0.5) +
                                      facet_grid(~LG,scales = 'free_x', space = 'free_x') + theme_classic() + ylim(0,1) + 
                                      scale_x_continuous(breaks = seq(5, 200, by = 5)) +
                                      theme(
                                        strip.background = element_rect(color="white", fill="gray", size=1.5, linetype="solid"),
                                        strip.text.x = element_text(size = 10, color = "white")) + ylab("PC1 correlation") +
                                      xlab("Location (Mb)")
            corrPC1_plot
            corrPC2_plot <- ggplot(data=data_for_20_largest_scaffolds, aes(x=start/1000000,y=corr_pc2)) +
                                      geom_point(colour='black', size = 0.5, alpha = 0.5) +
                                      facet_grid(~LG,scales = 'free_x', space = 'free_x') + theme_classic() + ylim(0,1) + 
                                      scale_x_continuous(breaks = seq(5, 200, by = 5)) + 
                                      theme(
                                        strip.background = element_rect(color="white", fill="gray", size=1.5, linetype="solid"),
                                        strip.text.x = element_text(size = 10, color = "white")) + ylab("PC2 correlation") + 
                                      xlab("Location (Mb)")
            corrPC2_plot

# Show the two plots together on a panel:
            library(cowplot)
            plot_grid(corrPC1_plot, corrPC2_plot, labels = c('a', 'b'), ncol = 1)

# -------------------------------------------------------------------------------








