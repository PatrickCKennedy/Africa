# PK (local computer R script)
# In this script, we correlate the PC scores of each genomic SA_window with the whole-genome PC scores. To run it, you
# must already have completed '2_PCANGSD_in_genomic_SA_windows.sh' on HPC. 

# Some parts of this script use and adapts various parts of the R scripts provided by Merot et al. (2011) in their PCANGSD analysis pipeline. We therefore
# cite Merot et al. (2011) as the source of those analyses.

# You can run this script on any output from PCANGSD that uses the PCA SA_windows script. So that could be on the whole (three climates) data, or just the data
# from a single country. Make sure to import the data corresponding to the right analysis by changing the folders used below.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# SECTION TO RUN FIRST IN BASH IN THE TERMINAL:

# To run the commands below, you must first download the relevant files from BluePebble:

       # (1) Download the SouthAfrica_only results:
        cd Downloads
        scp -r pk14885@bp1-login.acrc.bris.ac.uk:/user/work/pk14885/Wasps/Completed_alignments/juncea_PCANGSD_results_for_SouthAfrica_ONLY juncea_PCANGSD_results_for_SouthAfrica_ONLY

# -------------------------------------------------------------------------------
# The rest of this script is for R.
# -------------------------------------------------------------------------------

# ANALYSES IN THIS R SCRIPT:
        # (1) WHOLE-GENOME PCA [partly adapted from scripts in Merot et al. (2021) pipeline]
        # (2) LOCAL GENOMIC SA_windowS PCA (AND RESULTING CORRELATION WITH WHOLE-GENOME PCA) [adapted from scripts in Merot et al. (2021) pipeline]

# -----------------------------------------------------------------------------------
## (1) RUNNING PCA ON THE WHOLE-GENOME COV FILE:
# following https://github.com/clairemerot/angsd_pipeline/blob/master/01_scripts/Rscripts/make_pca_simple.r
# This section just essentially repeats the analysis that we have already run in the script '1_Analysing PCANGSD results in R.R'
# However, we need to import the data to this script in order to construct the correlation plots with the SA_windows later on in the script.

# Set the working directory to the folder '04_pca', which contains the whole-genome PCA covariance file:
        setwd("/Users/pk14885/Downloads/juncea_PCANGSD_results_for_SouthAfrica_ONLY/")

# Import the right covariance file and call it 'cov_mat':
        SA_cov_mat<-as.matrix(read.table("04_pca/all_maf0.05_pctind0.5_maxdepth20.cov"), header=F)

# Also download the WaspNameList and PopulationLabels files from BluePebble:
        SA_WaspNameList<-read.table("SouthAfrica_ONLY.WaspNameList",head=F)
        SA_PopulationLabels<-read.table("SouthAfrica_ONLY.PopulationLabels",head=F)

# Eigendecomposition to find the PCA:
        SA_pca<-eigen(SA_cov_mat)
        SA_pca.mat<-as.matrix(SA_pca$vectors %*% (diag(SA_pca$values))^0.5)

# Add titles to the columsn of the 'pca.mat' matrix:
        nPC<-dim(SA_pca$vectors)[2]
        SA_col_PC<-vector(length=nPC)
        for (i in 1 : nPC) {SA_col_PC[i]<-paste0("PC",i)}
        colnames(SA_pca.mat)<-c(SA_col_PC)

#add rownames
#bam_names<-read.table(BAM,header=F)
#rownames(pca.mat)<-bam_names$V1

# Calculate how much variance is explained by each principal component:
        SA_var1<-round(SA_pca$values[1]*100/sum(SA_pca$values[SA_pca$values>=0]),2)
        SA_var2<-round(SA_pca$values[2]*100/sum(SA_pca$values[SA_pca$values>=0]),2)
        SA_var3<-round(SA_pca$values[3]*100/sum(SA_pca$values[SA_pca$values>=0]),2)
        SA_var4<-round(SA_pca$values[4]*100/sum(SA_pca$values[SA_pca$values>=0]),2)

#make kmeans for 3 groups on PC1
#kmeans_res<-kmeans(as.matrix(SA_pca.mat[,1]), c(min(SA_pca.mat[,1]), median(SA_pca.mat[,1]), max(SA_pca.mat[,1])))
#k_ss<-round(kmeans_res$betweenss/kmeans_res$totss,3)

# Plot the first two components of the PCA:
        plot(SA_pca.mat[,1], SA_pca.mat[,2], pch=20, ylab=paste("PC2", SA_var2), xlab=paste("PC1", SA_var1))

# Save the whole-genome PCA matrix (keeping the first four components) with the name 'info_pc' (we will use it below):
        info_pc <- SA_pca.mat[,1:4]

SA_pca.mat.df <- as.data.frame(SA_pca.mat)
SA_pca.mat.df$Pop <- SA_PopulationLabels

SA_my_PCs_to_plot <- as.data.frame(cbind(SA_pca.mat[,1],SA_pca.mat[,2]))
SA_my_PCs_to_plot$V3 <- SA_PopulationLabels
SA_my_PCs_to_plot$V4 <- SA_WaspNameList
        
library(ggplot2)
my_SA_PCA_plot <- ggplot(SA_my_PCs_to_plot, aes(x=V1, y=V2, col = as.factor(V3$V1), shape = as.factor(V3$V1))) +
    geom_point(size = 2) + 
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_blank(), 
          axis.line = element_line(size = 0), 
          panel.border = element_rect(colour = "black", fill=NA, size=1)) + 
    labs(
        x = paste("PC1 (",round(SA_var1,1),"%)",sep=""), 
        y = paste("PC2 (",round(SA_var2,1),"%)",sep="")) + 
    theme(legend.title=element_blank()) + theme(legend.key = element_rect(fill = NA, color = NA)) +
    guides(colour = guide_legend(override.aes = list(size=2))) + 
    theme(legend.text=element_text(size=8)) + 
    theme(legend.background=element_blank()) + 
    theme(legend.spacing.x = unit(0.01, 'cm'),
          legend.spacing.y = unit(0.01, 'cm'),
          legend.key.height = unit(0.1, "cm")) + 
    theme(legend.direction = "vertical",
          legend.box = "horizontal",
          legend.position = "bottom") + scale_shape_manual(values = c(4,8,15,16,17,18,21,22)) 
my_SA_PCA_plot

my_SA_PCA_plot_with_zoomed_region <- my_SA_PCA_plot + 
                                          facet_zoom(x = V1 < 0,
                                                     y = V2 > -0.1 & V2 < 0.005)

# -------------------------------------------------------------------------------
# (2) NOW RUN PCA ON THE LOCAL SA_windowS OF THE GENOME (AND CORRELATE THEM TO THE GLOBAL PCA ABOVE):

# Set the working directory to the folder containing the downloaded SA_window data:
setwd("/Users/pk14885/Downloads/juncea_PCANGSD_results_for_SouthAfrica_ONLY/10_pca_by_SA_window/all_maf0.05_pctind0.5_maxdepth20/1000")

# Load the 'lostruct' library (note: "If you use this method, please cite Li & Ralph 2019" [https://github.com/petrelharp/local_pca])
      library(lostruct)

# Make sure the correct input values from the ANGSD run are specified here:
        MIN_MAF = 0.05
        PERCENT_IND = 0.5
        SA_window_SIZE = 1000
        MAX_DEPTH_FACTOR = 20
        N_ind = dim(SA_WaspNameList)[1]
        N_PC = 2
        N_MDS = 2

# Import the text file containing the list of analysed SA_windows:
      SA_window<-read.table(("analyse_by_window/list_window.txt"),header=F)
      colnames(SA_window)<-"file_name"
      View(SA_window)

# Set up an empty table in which we will record the key information (e.g., start and stop position) of each SA_window:
      SA_window$LG<-vector(length=dim(SA_window)[1])
      SA_window$pos<-vector(length=dim(SA_window)[1])
      SA_window$n_snp<-vector(length=dim(SA_window)[1])
      SA_window$start<-vector(length=dim(SA_window)[1])
      SA_window$stop<-vector(length=dim(SA_window)[1])

# Now fill in the details in that table:
      for (i in 1:dim(SA_window)[1] )
      {
        SA_window$LG[i]<-unlist(strsplit(as.character(SA_window$file_name[i]), split="_"))[3]
        SA_window$pos[i]<-unlist(strsplit(as.character(SA_window$file_name[i]), split="_"))[4]
        SA_window$n_snp[i]<-as.numeric(unlist(strsplit(as.character(SA_window$file_name[i]), split="_"))[5])
        SA_window$start[i]<-as.numeric(unlist(strsplit(as.character(SA_window$pos[i]), split="-"))[1])
        SA_window$stop[i]<-as.numeric(unlist(strsplit(as.character(SA_window$pos[i]), split="-"))[2])
      }

# P: Remove the 'arg' files (we only want the 'cov' files):
      SA_window[- grep("arg", SA_window$file_name),] -> SA_window

# Re-order the SA_windows:
      SA_window_order<-SA_window[order(SA_window$LG, SA_window$start),]
      View(SA_window_order)

# Running 'lostruct' on each SA_window:
      
      # "prepare an empty matrix with nrow= nb of SA_window, and ncol= sumofsquares + nb of eigen value + dim of all eigen vectors (Nb individuals * N_Pc)" (Moret et al., 2021)
                SA_window_eigs<-matrix(nrow=dim(SA_window_order)[1], ncol= (1+N_PC+ (N_ind*N_PC)))
      
      # Eigendecomposition on each SA_window's covariance file:
                for (i in 1: dim(SA_window_order)[1])
                {
                  print(paste("import covariance matrix for SA_window and get eigenvectors",i))
                  SA_window_covmats_i<-as.matrix(read.table(paste0("cov_by_window/",SA_window_order$file_name[i])))
                  SA_window_eigs[i,]<- cov_pca(k=N_PC, covmat=SA_window_covmats_i)
                }

      # "run lostruct fonctions to calculate  distances between pca made on each SA_window":
                print(paste("calculating distance between SA_window PCA with NPC=",N_PC))
                SA_window_dist<- pc_dist(SA_window_eigs, npc=N_PC)

      # "run a MDS to visualise the distribution of SA_window"
              print(paste("run MDS on distance matrix and will keep N_MDS=",N_MDS))
              mds_axe<-cmdscale(SA_window_dist, eig=TRUE, k=N_MDS)
              SA_window_order_mds<-cbind(SA_window_order, mds_axe$points)

# Plot the different MDS axes:
              print("plotting MDS axis")
              plot(mds_axe$points[,1], mds_axe$points[,2], pch=20)


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# First, correlate the local-SA_window PC1s with the global PC1 and PC2 axes:

# Calculate the correlation between each local-SA_window's PCs and the full whole-genome PCA, "to see which portions of the genome are associated
# with the structure seen on the first 3 PCs of the PCa on the whole genome":
            SA_window_order1 <- SA_window_order
            for (i in 1: dim(SA_window_order)[1])
            {
              print(paste("calculating corr pca for SA_window",i))
              PC_mat_i<- t(rbind(SA_window_eigs[i,4:(3+N_ind)],SA_window_eigs[i,(4+N_ind):(3+2*N_ind)]))
              SA_window_order1$eig_pc1[i]<-SA_window_eigs[i,1] #not sure which number is eigenvalue or sum of square and how to get variance from there
              SA_window_order1$eig_pc2[i]<-SA_window_eigs[i,2]
              SA_window_order1$corr_pc1[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,1])$estimate)
              SA_window_order1$corr_pc2[i]<-abs(cor.test(PC_mat_i[,1], info_pc[,2])$estimate)
            }

# P: Focus on the 10 largest scaffolds and make a ggplot:
            library(ggplot2)
            SA_window_order1$LG <- as.numeric(SA_window_order$LG)
            data_for_10_largest_scaffolds = subset(SA_window_order1,SA_window_order1$LG<11)
            localPC1_corr_globalPC1_plot <- ggplot(data=data_for_10_largest_scaffolds, aes(x=start/1000000,y=corr_pc1)) +
                                      geom_point(colour='black', size = 0.2, alpha = 0.5) +
                                      facet_grid(~LG,scales = 'free_x', space = 'free_x') + theme_classic() + ylim(0,1) + 
                                      theme(
                                        axis.line = element_line(colour = 'black', size = 0.5),      
                                        strip.background = element_rect(color="gray", fill="gray", size=0.5, linetype="solid"),
                                        strip.text.x = element_text(size = 6, color = "white")) + ylab(expression(rho*"PC1"))  +
                                      xlab("Genomic location (Mb)") + 
                                      geom_line(alpha = 0.2) +
                                        scale_x_continuous(breaks = seq(5, 200, by = 15)) +
                                        scale_y_continuous(breaks = seq(0, 1, by = 1), limits = c(0,1))
            localPC1_corr_globalPC1_plot
            localPC1_corr_globalPC2_plot <- ggplot(data=data_for_10_largest_scaffolds, aes(x=start/1000000,y=corr_pc2)) +
                                      geom_point(colour='black', size = 0.2, alpha = 0.5) +
                                      facet_grid(~LG,scales = 'free_x', space = 'free_x') + theme_classic() + ylim(0,1) + 
                                      theme(
                                        axis.line = element_line(colour = 'black', size = 0.5), 
                                        strip.background = element_rect(color="gray", fill="gray", size=0.5, linetype="solid"),
                                        strip.text.x = element_text(size = 6, color = "white")) + ylab(expression(rho*"PC2"))  + 
                                      xlab("Genomic location (Mb)") + 
                                      geom_line(alpha = 0.2) +
                                        scale_x_continuous(breaks = seq(5, 200, by = 15)) + 
                                        scale_y_continuous(breaks = seq(0, 1, by = 1), limits = c(0,1))
            localPC1_corr_globalPC2_plot

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Second, correlate the local-SA_window PC2s with the global PC1 and PC2 axes:

# Calculate the correlation between each local-SA_window's PCs and the full whole-genome PCA, "to see which portions of the genome are associated
# with the structure seen on the first 3 PCs of the PCa on the whole genome":
            SA_window_order2 <- SA_window_order
            for (i in 1: dim(SA_window_order)[1])
            {
              print(paste("calculating corr pca for SA_window",i))
              PC_mat_i<- t(rbind(SA_window_eigs[i,4:(3+N_ind)],SA_window_eigs[i,(4+N_ind):(3+2*N_ind)]))
              SA_window_order2$eig_pc1[i]<-SA_window_eigs[i,1] #not sure which number is eigenvalue or sum of square and how to get variance from there
              SA_window_order2$eig_pc2[i]<-SA_window_eigs[i,2]
              SA_window_order2$corr_pc1[i]<-abs(cor.test(PC_mat_i[,2], info_pc[,1])$estimate)
              SA_window_order2$corr_pc2[i]<-abs(cor.test(PC_mat_i[,2], info_pc[,2])$estimate)
            }

# P: Focus on the 10 largest scaffolds and make a ggplot:
            SA_window_order2$LG <- as.numeric(SA_window_order$LG)
            data_for_10_largest_scaffolds = subset(SA_window_order2,SA_window_order2$LG<11)
            localPC2_corr_globalPC1_plot <- ggplot(data=data_for_10_largest_scaffolds, aes(x=start/1000000,y=corr_pc1)) +
                                      geom_point(colour='black', size = 0.2, alpha = 0.5) +
                                      facet_grid(~LG,scales = 'free_x', space = 'free_x') + theme_classic() + ylim(0,1) + 
                                      theme(
                                        axis.line = element_line(colour = 'black', size = 0.5),      
                                        strip.background = element_rect(color="gray", fill="gray", size=0.5, linetype="solid"),
                                        strip.text.x = element_text(size = 6, color = "white")) + ylab(expression(rho*"PC1"))  +
                                      xlab("Genomic location (Mb)") + 
                                      geom_line(alpha = 0.2) +
                                        scale_x_continuous(breaks = seq(5, 200, by = 15)) +
                                        scale_y_continuous(breaks = seq(0, 1, by = 1), limits = c(0,1))
            localPC2_corr_globalPC1_plot
            localPC2_corr_globalPC2_plot <- ggplot(data=data_for_10_largest_scaffolds, aes(x=start/1000000,y=corr_pc2)) +
                                      geom_point(colour='black', size = 0.2, alpha = 0.5) +
                                      facet_grid(~LG,scales = 'free_x', space = 'free_x') + theme_classic() + ylim(0,1) + 
                                      theme(
                                        axis.line = element_line(colour = 'black', size = 0.5), 
                                        strip.background = element_rect(color="gray", fill="gray", size=0.5, linetype="solid"),
                                        strip.text.x = element_text(size = 6, color = "white")) + ylab(expression(rho*"PC2"))  + 
                                      xlab("Genomic location (Mb)") + 
                                      geom_line(alpha = 0.2) +
                                        scale_x_continuous(breaks = seq(5, 200, by = 15)) + 
                                        scale_y_continuous(breaks = seq(0, 1, by = 1), limits = c(0,1))
            localPC2_corr_globalPC2_plot

# Show the three plots together on a panel:
        library(cowplot)
        my_output_panel <- ggdraw() +
            draw_plot(my_SA_PCA_plot_with_zoomed_region,  x=0, y=.5, width= .3, height=.5) +
                draw_plot_label(label = "a", x = 0, y = 1, size = 10) + 
            draw_plot(localPC1_corr_globalPC1_plot,  x=.3, y=.5, width= .7, height=.5) +
                draw_plot_label(label = "b", x = 0.3, y = 1, size = 10) + 
            draw_plot(localPC2_corr_globalPC2_plot,  x=.3, y=0, width= .7, height=.5) +
                draw_plot_label(label = "c", x = 0.3, y = 0.5, size = 10)
        my_output_panel




