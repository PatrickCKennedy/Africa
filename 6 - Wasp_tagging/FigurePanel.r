# FIRST RUN THESE TWO SCRIPTS:

# Processing_egg_size
# Processing_wasp_tagging

# THEN COMBINE THE OUTPUTS INTO A PANEL AS FOLLOWS:

library("cowplot")
my_output_panel4 <- ggdraw() +
    draw_plot(ovarystage.plot + theme(legend.position = c(-0.34, -0.17)), x=0, y=0.5, width= 0.25, height=0.5) +
    draw_plot(largestegg.plot,  x=.25, y=0.5, width= 0.25, height=0.5) +
    draw_plot(thoraxwidth_plot, x=.5, y=0.5, width= 0.25, height=0.5) +
    draw_plot(winglength_plot,  x=.75, y=0.5, width= 0.25, height=0.5) +
    draw_plot(Cameroon.THORAX.dominantsubordinatesizeplot,  x=0, y=0, width= 0.25,height=0.5) +
    draw_plot(SA.THORAX.dominantsubordinatesizeplot,  x=.25, y=0, width= 0.25,height=0.5) +
    draw_plot(Cameroon.WINGS.dominantsubordinatesizeplot,  x=.5, y=0, width= 0.25,height=0.5) +
    draw_plot(SA.WINGS.dominantsubordinatesizeplot,  x=.75, y=0, width= 0.25,height=0.5) +
    draw_plot_label("a", x = 0, y = 1, size = myfontsize, fontface = "bold") +
    draw_plot_label("b", x = .25, y = 1, size = myfontsize, fontface = "bold") +
    draw_plot_label("c", x = .5, y = 1, size = myfontsize, fontface = "bold") +
    draw_plot_label("d", x = .75, y = 1, size = myfontsize, fontface = "bold") +
    draw_plot_label("e", x = 0, y = 0.5, size = myfontsize, fontface = "bold") +
    draw_plot_label("f", x = .25, y = 0.5, size = myfontsize, fontface = "bold") +
    draw_plot_label("g", x = .5, y = 0.5, size = myfontsize, fontface = "bold") +
    draw_plot_label("h", x = .75, y = 0.5, size = myfontsize, fontface = "bold")
my_output_panel4

# Export as SVG file for publication:
library(svglite)
ggsave(filename = "my_output_panel4.svg", 
       plot = my_output_panel4, 
       height = 5,
       width = 6, dpi = 200)
# This file is now in the relevant folder, as an SVG file. 
# Opening it will open Inkscape automatically.
