YaoundePlot <- ggplot() +
  geom_step(data=subset(PSMC_data_Yaounde, PSMC_data_Yaounde$V6==" Yaounde bootstrap "), 
            aes(x=V1, y=V2*10, group=V7), color="cyan", alpha=0.03) +
  geom_step(data=subset(PSMC_data_Yaounde, PSMC_data_Yaounde$V6==" Yaounde "), 
            aes(x=V1, y=V2*10, group=V7), color="navy", alpha = 0.5) +
  scale_x_log10( #set limits, breaks, labels however you please
    limits=c(11000, 1000000),
    #  breaks = c(10000,100000,1000000, 10000000),
    #  labels = c("10000","100000","1000000", "10000000")
  ) +
  scale_y_continuous(
    #  expand=c(0,0), limits = c(0,1250), breaks = c(seq(0,1250,250)) #set limits, breaks, labels however you please
  ) +
  theme_classic(base_size = 12) +
  theme(axis.title.x = element_text(size = 12,family = "Helvetica"),
        axis.title.y = element_text(size = 12),
        axis.text.y = element_text(size = 12,color = "black"),
        axis.text = element_text(size = 12,color = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.position = "none") +
  xlab("Years ago") +
  ylab(expression(paste("Effective population size (N"[e], " x", 10^{3}, ")",sep=" "))) + #can change scaling so 10^4, 10^6 etc, just also modify the scaling factor in geom_step(). psmc plot automatically outputs 10^4
  annotation_logticks(side = "b") + theme(panel.border = element_rect(color = "black",fill = NA,size = 1))

YaoundePlot + geom_step(data=subset(
  PSMC_data_Magaliesberg, 
  PSMC_data_Magaliesberg$V6==" Magaliesberg bootstrap "), 
  aes(x=V1, y=V2*10, group=V7), 
  color="orange", alpha=0.03) + 
  geom_step(data=subset(
    PSMC_data_Magaliesberg, 
    PSMC_data_Magaliesberg$V6==" Magaliesberg "), 
    aes(x=V1, y=V2*10, group=V7), 
    color="orange")



