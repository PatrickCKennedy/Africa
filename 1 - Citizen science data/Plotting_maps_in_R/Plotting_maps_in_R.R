# PK
# Plotting and analysing iNaturalist observations

library(readxl)
library("tidyverse")
library(tidyr) 

# Import the Excel file containing the observations
iNaturalist_observations <- read_excel("Desktop/iNat_obs_table.xlsx")
View(iNaturalist_observations)

# ------------------------------------------------------------------------------
# ARE FOUNDRESS GROUP SIZES DIFFERENT ACROSS THE CONTINENT?

# Extract foundress nests:
FoundressNests <- subset(iNaturalist_observations, iNaturalist_observations$`Automatic: categorisation, with all foundress nests listed as "Nest (foundress)" only:` == 'Nest (foundress)')

# Remove rows that contain 'No adult presents' or 'NA' in the group size column:
FoundressNests <- subset(FoundressNests, FoundressNests$`If nest: total group size (females or males)` != "No adults present")
FoundressNests <- subset(FoundressNests, FoundressNests$`If nest: total group size (females or males)` != "NA")

# Remove rows that contain 'NA' in the latitude column:
FoundressNests <- subset(FoundressNests, FoundressNests$latitude != "NA")

# Focus just on latitude, longitude, location code, group size, presence or absence of pleometrosis, and observation type:
FoundressData <- cbind(FoundressNests$latitude,FoundressNests$longitude,FoundressNests$LocationCode,FoundressNests$`If nest: total group size (females or males)`,FoundressNests$Pleometrosis, FoundressNests$Type)
colnames(FoundressData) <- c("latitude","longitude","locationcode","group_size","pleometrosis","type")
FoundressData <- as.data.frame(FoundressData)

# Remove observations with ambiguous group size (i.e., observations with text notes as group size entries):
FoundressDataNonAmbiguousGroupSize <- FoundressData
FoundressDataNonAmbiguousGroupSize$group_size <- as.numeric(FoundressDataNonAmbiguousGroupSize$group_size)
temp <- subset(FoundressDataNonAmbiguousGroupSize,!is.na(FoundressDataNonAmbiguousGroupSize$group_size))
FoundressDataNonAmbiguousGroupSize <- temp

# Plot foundress group size against latitude:
plot(as.numeric(FoundressDataNonAmbiguousGroupSize$latitude),FoundressDataNonAmbiguousGroupSize$group_size)

# To check if this a bimodal distribution, we use Hartigan's dip test for unimodality/multimodality:
latitude_and_foundressgroupsize <- cbind(as.numeric(FoundressDataNonAmbiguousGroupSize$latitude),as.numeric(FoundressDataNonAmbiguousGroupSize$group_size))
colnames(latitude_and_foundressgroupsize) <- c("latitude","group_size")
library(diptest)
dip.test(latitude_and_foundressgroupsize)
# e.g., output on 7/12/2023: D = 0.064116, p-value < 2.2e-16
# It is bimodal because of uneven sampling focused on Cameroon and South Africa

latitude_and_foundressgroupsize <- as.data.frame(latitude_and_foundressgroupsize)
ggplot(latitude_and_foundressgroupsize, aes(latitude, fill = as.character(group_size))) + geom_histogram(bins = 10, position = 'fill') +   scale_fill_brewer()

# Add a binary variable for pleometrosis:
#FoundressData$is.pleometrosis <- ifelse(FoundressData$group_size>1, 1, 0)

# ------------------------------------------------------------------------------
library(rnaturalearth)
library(sf)


# Plot our map of the world
FoundressDataNonAmbiguousGroupSize$latitude <- as.numeric(FoundressDataNonAmbiguousGroupSize$latitude)
FoundressDataNonAmbiguousGroupSize$longitude <- as.numeric(FoundressDataNonAmbiguousGroupSize$longitude)

# Select just the continent of Africa
world_map <- ne_countries(scale = "small", returnclass = "sf")
africa <- world_map %>% 
  filter(continent %in% "Africa")

ggplot(data = africa) +
  geom_sf(fill = "antiquewhite", alpha = 0.3) + 
  geom_point(data = FoundressDataNonAmbiguousGroupSize,
             aes(x = longitude,
                 y = latitude,
                 size = group_size),
             alpha = 0.2,
             colour = "black") +
  theme(panel.grid.major = element_line(color = gray(.0), 
                                        size = 0), 
        panel.background = element_rect(fill = "white")) +
  labs(title = "Foundress group size")

# ----------------------------------------------------------------------
# DOES FOUNDRESS GROUP SIZE CORRELATE WITH CLIMATE VARIABLES?


library(sp)

# Old version using raster function (function now removed):
library(raster)
#r <- raster::getData("worldclim",var="bio",res=10)

# New version using geodata function:
path = file.path( R.home(), "etc/Rprofile.site")
library(geodata)
s <- worldclim_global(var="bio", res=10, path = path, version="2.1")
r <- s

r <- r[[c(1,12,4,7,15)]]
names(r) <- c("Temp","Prec","Seasonality","AnnualTempRange","RainSeasonality")
points <- cbind(as.numeric(FoundressDataNonAmbiguousGroupSize$longitude),as.numeric(FoundressDataNonAmbiguousGroupSize$latitude))
values <- raster::extract(r,points)
FoundressDataNonAmbiguousGroupSize <- cbind.data.frame(FoundressDataNonAmbiguousGroupSize,values)
plot(FoundressDataNonAmbiguousGroupSize$Temp,FoundressDataNonAmbiguousGroupSize$group_size)

# Is there a significant effect of temperature on foundress group size?
ggplot(FoundressDataNonAmbiguousGroupSize, aes(Temp, as.numeric(group_size))) +
  geom_point(data = FoundressDataNonAmbiguousGroupSize,
             aes(x = longitude,
                 y = latitude),
             alpha = 0.5,
             size = 1,
             colour = "black")

model <- lm(group_size ~ Temp, data = FoundressDataNonAmbiguousGroupSize)
model
summary(model)

# Is there a significant effect of rainfall on foundress group size?
ggplot(FoundressDataNonAmbiguousGroupSize, aes(Prec, as.numeric(group_size))) +
  geom_point() +
  stat_smooth(method = lm)

model <- lm(group_size ~ Prec, data = FoundressDataNonAmbiguousGroupSize)
model
summary(model)

# Using a GAMS approach (https://m-clark.github.io/generalized-additive-models/application.html):

  # FirSt, the standard linear regression (but using the GAM function):
    library(mgcv)
    mod_lm = gam(as.numeric(pleometrosis) ~ latitude, data = FoundressDataNonAmbiguousGroupSize, family = binomial)
    summary(mod_lm)
    # Should give the same result as the lm() function.

  # Now, fitting a GAM model:
   mod_gam1 = gam(as.numeric(pleometrosis) ~ s(latitude, bs = "cr"), data = FoundressDataNonAmbiguousGroupSize, family = binomial)
    summary(mod_gam1)
    plot(mod_gam1)     

  # Plotting the GAM model using the 'visibly' package (https://m-clark.github.io/visibly/):
  ##devtools::install_github("m-clark/visibly")          
  library(visibly)
  plot_gam(mod_gam1, main_var = latitude)                                       
                                           






















# Is there a significant effect of RainSeasonality on foundress group size?
ggplot(FoundressDataNonAmbiguousGroupSize, aes(RainSeasonality, as.numeric(group_size))) +
  geom_point() +
  stat_smooth(method = lm)

model <- lm(group_size ~ RainSeasonality, data = FoundressDataNonAmbiguousGroupSize)
model
summary(model)

# Is there a significant effect of AnnualTempRange on foundress group size?
ggplot(FoundressDataNonAmbiguousGroupSize, aes(AnnualTempRange, as.numeric(group_size))) +
  geom_point() +
  stat_smooth(method = lm)

model <- lm(group_size ~ AnnualTempRange, data = FoundressDataNonAmbiguousGroupSize)
model
summary(model)

# Is there a significant effect of latitude on foundress group size?
ggplot(FoundressDataNonAmbiguousGroupSize, aes(latitude, as.numeric(group_size))) +
  geom_point() +
  stat_smooth(method = lm)

model4 <- lm(group_size ~ latitude, data = FoundressDataNonAmbiguousGroupSize)
model4
summary(model)              
# ----------------------------
# Comparing regions:

SouthernAfrica <- subset(FoundressDataNonAmbiguousGroupSize, latitude < -20)
hist(as.numeric(SouthernAfrica$group_size))

EastAfrica <- subset(FoundressDataNonAmbiguousGroupSize, latitude > -10 & longitude > 25)
hist(as.numeric(EastAfrica$group_size))

WestAfrica <- subset(FoundressDataNonAmbiguousGroupSize, latitude > -10 & longitude < 15)
hist(as.numeric(WestAfrica$group_size))

# Add these regional categories as columns to the dataset:
FoundressDataNonAmbiguousGroupSize$Region <- NA
FoundressDataNonAmbiguousGroupSize$Region <-  ifelse(FoundressDataNonAmbiguousGroupSize$latitude < -10, "Southern Africa", FoundressDataNonAmbiguousGroupSize$Region)
FoundressDataNonAmbiguousGroupSize$Region <-  ifelse(FoundressDataNonAmbiguousGroupSize$latitude > -10 & FoundressDataNonAmbiguousGroupSize$longitude > 20, "East Africa", FoundressDataNonAmbiguousGroupSize$Region)
FoundressDataNonAmbiguousGroupSize$Region <-  ifelse(FoundressDataNonAmbiguousGroupSize$latitude > -10 & FoundressDataNonAmbiguousGroupSize$longitude < 10, "West Africa", FoundressDataNonAmbiguousGroupSize$Region)

model <- glm( as.numeric(pleometrosis) ~ Region, data = FoundressDataNonAmbiguousGroupSize, family = binomial)
summary(model)$coef 

ggplot(data=FoundressDataNonAmbiguousGroupSize, aes(x=as.numeric(group_size), fill=Region)) +
  geom_density(alpha=0.5, bw = 2) +
  xlim(1,10) +
  theme_classic()
# Wait a sec. This is biased, because it only includes the single foundresses from Keeping and drops the multi-foundress nests (which have text in the Excel spreadsheet)

# ------------------------------------------------------------------------------
# PLEOMETROSIS OR HAPLOMETROSIS? Logistic regression following http://www.sthda.com/english/articles/36-classification-methods-essentials/151-logistic-regression-essentials-in-r/

# Now going back to the main 'FoundressData' dataset (i.e., before FoundressDataNonAmbiguousGroupSize):
FoundressData$latitude <- as.numeric(FoundressData$latitude)
FoundressData$longitude <- as.numeric(FoundressData$longitude)

model <- glm( as.numeric(pleometrosis) ~ latitude, data = FoundressData, family = binomial)
summary(model)$coef

FoundressData %>%
  mutate(prob = as.numeric(pleometrosis)) %>%
  ggplot(aes(latitude, prob)) +
  geom_point(alpha = 0.2) +
  geom_smooth(method = "glm", method.args = list(family = "binomial")) +
  labs(
    title = "Logistic Regression Model", 
    x = "Latitude",
    y = "Probability of cooperation"
  )

FoundressDataNonAmbiguousGroupSize %>%
  mutate(prob = as.numeric(pleometrosis)) %>%
  ggplot(aes(latitude, prob)) +
  geom_point(alpha = 0.2) +
  geom_smooth(method = "glm", method.args = list(family = "binomial")) +
  labs(
    title = "Logistic Regression Model", 
    x = "Latitude",
    y = "Probability of cooperation"
  )

model <- glm( as.numeric(pleometrosis) ~ latitude, data = FoundressDataNonAmbiguousGroupSize, family = binomial)
summary(model)$coef

# The simple model above has no random effects.

# A more appropriate way is to use proportions in each site:

locationsList <- unique(FoundressDataNonAmbiguousGroupSize$locationcode)

pleometrosis_only_subset <- subset(FoundressDataNonAmbiguousGroupSize, pleometrosis==1)

# Make table to store proportions pleometrosis:
SitePleometrosisProportions <- as.data.frame(locationsList)
SitePleometrosisProportions$PleometrosisCount <- NA
SitePleometrosisProportions$TotalCount <- NA
colnames(SitePleometrosisProportions)
colnames(SitePleometrosisProportions)[1] <- "locationcode"

for (site in 1:length(locationsList)){
  
  this_locationcode <- locationsList[site]
  
  # Find number of pleometrosis foundress nest observations at this site:
  number_pleometrosis_at_this_site <- sum(pleometrosis_only_subset$locationcode == this_locationcode)
  SitePleometrosisProportions$PleometrosisCount[site] <- number_pleometrosis_at_this_site
  
  # Find total number of foundress nest observations at this site:
  all_foundress_nests_at_this_site <- sum(FoundressDataNonAmbiguousGroupSize$locationcode == this_locationcode)
  SitePleometrosisProportions$TotalCount[site] <- all_foundress_nests_at_this_site
  
}

# Add latitude and longitude (and climate info) using R's version of VLOOKUP:
info_to_add <- cbind(FoundressDataNonAmbiguousGroupSize$locationcode,
                     FoundressDataNonAmbiguousGroupSize$latitude,
                     FoundressDataNonAmbiguousGroupSize$longitude,
                     FoundressDataNonAmbiguousGroupSize$type,
                     FoundressDataNonAmbiguousGroupSize$Temp,
                     FoundressDataNonAmbiguousGroupSize$Prec,
                     FoundressDataNonAmbiguousGroupSize$Seasonality,
                     FoundressDataNonAmbiguousGroupSize$AnnualTempRange,
                     FoundressDataNonAmbiguousGroupSize$RainSeasonality)
colnames(info_to_add) <- c("locationcode","latitude","longitude","type","temp","prec","seasonality","annualtemprange","rainseasonality")
SitePleometrosisProportions <- merge(SitePleometrosisProportions, info_to_add, by = 'locationcode')
SitePleometrosisProportions <- distinct(SitePleometrosisProportions)
SitePleometrosisProportions$latitude <- as.numeric(SitePleometrosisProportions$latitude)

model.log <- glm(cbind(PleometrosisCount, TotalCount-PleometrosisCount) ~ as.numeric(latitude), data = SitePleometrosisProportions, family = "binomial"); 
summary(model.log)

plot(prop.table(cbind(SitePleometrosisProportions$PleometrosisCount, SitePleometrosisProportions$TotalCount-SitePleometrosisProportions$PleometrosisCount), 1)[,1]~SitePleometrosisProportions$latitude, ylab="Proportion")

library(emmeans)
emmeans(model.log, ~latitude, at=list(latitude=10), type='response')

yhat.df <- emmeans(model.log, ~latitude, at=list(latitude=seq(-35,10,by=1)), type='response') %>%
  as.data.frame()

ggplot(SitePleometrosisProportions, aes(x=latitude)) +
  geom_ribbon(data=yhat.df, aes(ymin=asymp.LCL, ymax=asymp.UCL), fill='salmon', alpha=.4) +
  geom_line( data=yhat.df, aes(y=prob), color='red') +
  geom_point(aes(y=PleometrosisCount/TotalCount, size = TotalCount), alpha = 0.15) +
  labs(y='Probability of cooperation', x='Latitude') + theme_classic()

# I THINK THE ABOVE IS NOT YET CORRECT.
# If you include locationcode as a random term, the effect vanishes:
library(lme4)
model.log2 <- glmer(cbind(PleometrosisCount, TotalCount-PleometrosisCount) ~ as.numeric(latitude) + (1|locationcode), data = SitePleometrosisProportions, family = "binomial"); 
summary(model.log2)

# ----------------------------------------------------------------------
# DOES POST-EMERGENCE GROUP SIZE CORRELATE WITH CLIMATE VARIABLES?


# Extract PostEmergence nests:
PostEmergenceNests <- subset(iNaturalist_observations, iNaturalist_observations$`Automatic: categorisation, with all foundress nests listed as "Nest (foundress)" only:` == 'Nest (foundress)')

# Remove rows that contain 'No adult presents' or 'NA' in the group size column:
PostEmergenceNests$`If nest: total group size (females or males)` <- as.numeric(PostEmergenceNests$`If nest: total group size (females or males)`)
PostEmergenceNests <- subset(PostEmergenceNests, PostEmergenceNests$`If nest: total group size (females or males)` != "NA")

# Remove rows that contain 'NA' in the latitude column:
PostEmergenceNests <- subset(PostEmergenceNests, PostEmergenceNests$latitude != "NA")

# Focus just on latitude, longitude, location code, and group size:
PostEmergenceData <- cbind(PostEmergenceNests$latitude,PostEmergenceNests$longitude,PostEmergenceNests$LocationCode,PostEmergenceNests$`If nest: total group size (females or males)`)
colnames(PostEmergenceData) <- c("latitude","longitude","locationcode","group_size")
PostEmergenceData <- as.data.frame(PostEmergenceData)

# Plot foundress group size against latitude:
plot(as.numeric(PostEmergenceData$latitude),PostEmergenceData$group_size)

# Set to numeric:
PostEmergenceData$latitude <- as.numeric(PostEmergenceData$latitude)
PostEmergenceData$longitude <- as.numeric(PostEmergenceData$longitude)

# Add WorldClim data:
r <- raster::getData("worldclim",var="bio",res=10)
r <- r[[c(1,12,4,7,15)]]
names(r) <- c("Temp","Prec","Seasonality","AnnualTempRange","RainSeasonality")
points <- cbind(PostEmergenceData$longitude,PostEmergenceData$latitude)
values <- raster::extract(r,points)
PostEmergenceData <- cbind.data.frame(PostEmergenceData,values)
plot(PostEmergenceData$Temp,PostEmergenceData$group_size)


# Is there a significant effect of temperature on PostEmergence group size?
ggplot(PostEmergenceData, aes(Temp, as.numeric(group_size))) +
  geom_point() +
  stat_smooth(method = lm)

model3 <- lm(as.numeric(group_size) ~ Temp, data = PostEmergenceData)
model3
summary(model3)












library(ggplot2)
set.seed(42)

dataA <- rnorm(200, 3, sd = 2)
dataB <- rnorm(500, 5, sd = 3)

all <- data.frame(
  dataset = c(rep('A', length(dataA)),rep('B', length(dataB))),
  value   = c(dataA, dataB)
)

ggplot(latitude_and_foundressgroupsize, aes(latitude, fill = as.character(is.pleometrosis))) +
  geom_histogram(bins = 25, position = 'fill')













library(ggplot2)
latiude_and_foundressgroupsize <- as.data.frame(latiude_and_foundressgroupsize)
fit <- lm(group_size ~ latitude + I(latitude^2), data = latiude_and_foundressgroupsize)
prd <- data.frame(latitude = seq(from = -30, to = 20, length.out = 100))
err <- predict(fit, newdata = prd, se.fit = TRUE)

prd$lci <- err$fit - 1.96 * err$se.fit
prd$fit <- err$fit
prd$uci <- err$fit + 1.96 * err$se.fit

ggplot(prd, aes(x = latitude, y = fit)) +
  theme_bw() +
  geom_line() +
  geom_smooth(aes(ymin = lci, ymax = uci), stat = "identity") +
  geom_point(data = latiude_and_foundressgroupsize, aes(x = latitude, y = group_size))












#load libraries
library(raster)
library(ggplot2)

#open ASCII file using ‘raster’ command, which converts the ASCII to a raster object
map <- raster(“/your/path/to/file.asc”)

#convert the raster to points for plotting
map.p <- rasterToPoints(map)

#Make the points a dataframe for ggplot
df <- data.frame(map.p)
#Make appropriate column headings
colnames(df) <- c(“Longitude”, “Latitude”, “MAP”)

#Call in point data, in this case a fake transect (csv file with lat and lon coordinates)
sites <- data.frame(read.csv(“/your/path/to/pointfile.csv”))

#Now make the map
ggplot(data=df, aes(y=Latitude, x=Longitude)) +
  geom_raster(aes(fill=MAP)) +
  geom_point(data=sites, aes(x=x, y=y), color=”white”, size=3, shape=4) +
  theme_bw() +
  coord_equal() +
  scale_fill_gradient(“MAP (mm/yr)”, limits=c(0,2500)) +
  theme(axis.title.x = element_text(size=16),
        axis.title.y = element_text(size=16, angle=90),
        axis.text.x = element_text(size=14),
        axis.text.y = element_text(size=14),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.position = “right”,
        legend.key = element_blank()
  )

THE PRODUCT.

I’ve only allowed the colors to go up to 2,500 mm annual rainfall because I wanted to show how most of Africa has rainfall levels below 2,500 mm/yr. You can change this by messing with colors and the ‘scale_fill_gradient()’ command. ggplot2 has great online resources here, http://docs.ggplot2.org/current/#.
  
  
  
  
  
  
  
  
  
  
