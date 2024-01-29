# CHCs in SOUTH AFRICAN FOUNDRESSES:

# -----------------------------------------------------------------------------------------------
# IDENTIFYING PARENTAL NESTS:

# First, run the relatedness processing script. As part of that, you will generate the
# 'All' file, which we will use here. We extract all South African full-sister groups, which 
# we assume to have been brood from same parental nest:

SA.sisters <- subset(All, ida_Population == idb_Population & ida_Country == "SouthAfrica" & rab > 0.6)
SA.sisters <- cbind(SA.sisters$ida_WaspID,SA.sisters$idb_WaspID,SA.sisters$ida_Population)
colnames(SA.sisters) <- c("ida_WaspID","idb_WaspID","Population")
SA.sisters <- as.data.frame(SA.sisters)
View(SA.sisters)

# Identify networks of full-sisters:
    library(igraph)
    library(ggraph)
    net <- graph_from_data_frame(SA.sisters)
    ggraph(net,layout='stress') + geom_edge_fan()

# Give each network a number (i.e., identify membership of parent nests):
    parent_nest_inferrences <- igraph::components(net)
    ParentNests <- as.data.frame(parent_nest_inferrences$membership)
    colnames(ParentNests) <- "ParentNestID"
    ParentNests$Wasp <- rownames(ParentNests)
    View(ParentNests)

# Export table to Excel:
    library(openxlsx)
    write.xlsx(ParentNests, 'ParentNests.xlsx')

# -----------------------------------------------------------------------------------------------
# CHC ANALYSIS:








