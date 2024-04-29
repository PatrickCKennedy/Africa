library(ggplot2)
library(dplyr)
library(scales)
library(tidyr)

# Import 'Nest_info_table'.

foundressNestInfoOnly <- subset(Nest_info_table, Nest_info_table$`Is this a foundress nest?`=="Foundress")
foundressNestInfoOnly

foundressNestInfoOnly %>% 
  gather('key','value',-Nest, -Country) %>% 
  group_by(Country, key) %>% 
  summarise(mean = mean(value),
            sem = sd(value) / sqrt(n()),
            lower = (mean - sem),
            upper = (mean + sem))-> newdf

#Draw bar plot with ggplot2
plot <- ggplot(data=newdf, aes(x=Group, y=mean, fill=key)) + 
  geom_bar(stat="identity",
           position="stack",
           width = 0.4) +
  geom_errorbar(data = filter(newdf, key == 'Unlabeled'), aes(ymax=upper,  ymin=lower), stat = 'identity', position = 'identity', width=0.15) +
  xlab(" ") + 
  ylab("Percentage (%)") +
  scale_y_continuous(labels = function(bs) {paste0(bs, '%')}) +
  theme_classic(base_size = 16, base_family = "Helvetica") + 
  theme(axis.text.y=element_text(size=16, face="bold"), 
        axis.title.y=element_text(size=16, face="bold"),
        axis.text.x=element_text(angle=45,hjust=1,vjust=1, size=16, face="bold"),
        legend.position="right")
