# PK
# Plotting and analysing iNaturalist observations

rm(list = ls())
library(readxl)
library(tidyverse)
library(tidyr) 
library(stars)      
library(sf)         
library(ggplot2)    
library(patchwork) 

# Import the Excel file containing the observations
iNaturalist_observations <- read_excel("Desktop/iNaturalist_observations.xlsx")
View(iNaturalist_observations)

# ------------------------------------------------------------------------------
# (1) FIRST, PLOT FOCAL FIELD SITES:

# Plotting climate map of Africa, following https://bedatablog.netlify.app/post/download-and-illustrate-current-and-projected-climate-in-r/

##raster::getData(name = 'worldclim', var = 'bio', res = 10, path = "/Users/pk14885/WorldClim/")

# You can choose which bioclim variables to plot:
bio1 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio1.bil")
bio4 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio4.bil")
bio5 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio5.bil")
bio6 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio6.bil")
bio7 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio7.bil")
bio8 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio8.bil")
bio9 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio9.bil")
bio10 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio10.bil")
bio11 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio11.bil")
bio12 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio12.bil")
bio13 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio13.bil")
bio14 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio14.bil")
bio15 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio15.bil")
bio17 <- stars::read_stars("/Users/pk14885/WorldClim/wc5/bio17.bil")

# Colour palette:
temp_colors <- colorRampPalette(c("darkcyan", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c"))

nbreaks <- 50
plot(bio5, main = "",
     nbreaks = nbreaks,
     col = temp_colors(nbreaks - 1))

african_map <- rnaturalearth::ne_countries(continent = "africa", returnclass = "sf")
# The precision has to be set to a value > 0 to resolve internal boundaries.
st_precision(african_map) <- 1e9 # Required to
sf_use_s2(FALSE)
african_map <- st_union(african_map)
plot(african_map)

mybiovariabletoplot <- bio11[african_map]
plot(mybiovariabletoplot, main = "Annual temperature - 1960-1990",
     col = temp_colors(80))

my_continent_map <- ggplot() + 
  geom_stars(data = mybiovariabletoplot/10) +
  scale_fill_gradientn(name = "Coldest \nquarter (°C)",
                       colors = temp_colors(20),
                       limits = c(5,29),
                       na.value = "white") +
  geom_sf(data = african_map, fill = NA) +
  ggtitle("") +
  coord_sf(ylim = c(-40, 35), xlim = c(-15, 60)) +
  theme_void() + theme(legend.position = c(0.2, 0.3)) +
  theme(axis.text = element_blank(), 
        legend.text = element_text(size=9),
        legend.title=element_text(size=9)) + 
  theme(legend.key.size = unit(0.3, 'cm'))
my_continent_map

# Plotting sampling sites in R after marking them as placeholders in Google Earth Pro
# Before running this script, you should have exported a .kml containing all the sites from
# Google Earth Pro, by clicking 'Save Place As' on the folder containing all the placeholders.
# Then convert the result to a CSV file at https://www.gearthblog.com/blog/archives/2017/01/google-earth-placemarks-excel.html
# The CSV file will be called 'doc.csv'

# Import the CSV file to R:
doc <- read.csv("~/Downloads/doc.csv")
View(doc)

my_sites <- cbind(doc$Latitude,doc$Longitude)
my_sites <- as.data.frame(my_sites)

# Plot climate map with sampling sites:
mysitesmap <- my_continent_map + geom_point(data = my_sites, aes(x = V2, y = V1),
                              colour="black",
                              fill="white",
                              pch=21, size=1.2)
mysitesmap

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# (2) SECOND, PLOTTING INATURALIST RECORDS:

iNat_obs_table <- read_excel("Desktop/iNat_obs_table.xlsx")
##View(iNat_obs_table)

MapPlot <- my_continent_map + geom_point(data = iNat_obs_table, 
                        aes(y = latitude, 
                            x = longitude),
                        fill = "black",
                        col = "black",
                        alpha = 0.15,
                        pch=2, size=0.2) +
  geom_point(data = my_sites, aes(x = V2, y = V1),
               colour="black",
               fill="white",
               pch=21, size=1.5)
MapPlot
ggsave(file="test.svg", plot=MapPlot,  height=4)

