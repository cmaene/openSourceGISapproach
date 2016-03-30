rm(list = ls())
# if necessary, install packages
install.packages("rgdal", repos="http://cran.us.r-project.org")
install.packages("rgeos", repos="http://cran.us.r-project.org")
setwd("/home/cmaene/Documents/Luis")
library(sp)
library(rgdal)
library(rgeos)

# two inputs here
poly <- readOGR(".", "polygons", verbose = FALSE)
line <- readOGR(".", "highways", verbose = FALSE)

# this is specific to my data - i have two IDs
poly@data$osm_id <- ifelse(is.na(poly@data$osm_id),as.character(poly@data$osm_way_id),as.character(poly@data$osm_id))
poly@data <- poly@data[,!(names(poly@data) %in% "osm_way_id")] #drop second ID now

# save input projection info..assuming both inputs are in the same proj
projinfo <-proj4string(poly)
# more for preparation
cnames <- colnames(poly@data)
poly@data$area <- 0.000000
head(poly@data) # just checking

# calculate area for each polygon (in DD, since it's WGS84)
for (i in 1:length(poly)){
  area <- poly@polygons[[i]]@area
  poly@data[i,c("area")] <- area
}
# add centroid XY vars to each polygons
#poly@data <- cbind(poly@data,coordinates(poly))
#cnames <-c(cnames,"cenX","cenY")
colnames(poly@data)<-cnames

# convert polygons to centroid points
#polypt <- poly@data
#coordinates(polypt) <- c("cenX","cenY")

# buffer around the points
polybuff <- gBuffer(poly, byid=TRUE, width=0.02) # I think 0.01 degree is about 2km... just guessing
proj4string(polybuff)<-projinfo

# convert lines to points because it's easier to select sample pt
# we do this because we want the new comparison area OVER highways
linept <-as(line, 'SpatialPointsDataFrame')

newtable <- c(1:4) #temporarilly filling the final sample points
for (i in 1:length(polybuff)){
  polybuff_id <- polybuff@data[i,c("osm_id")]
  polybuff_area <- polybuff@data[i,c("area")]
  lineptclip <- gIntersection(linept, polybuff[polybuff$osm_id==polybuff_id,])
  temp=sample(lineptclip,3) #three samples each
  samp<-as.data.frame(coordinates(temp))
  samp$osm_id <- polybuff_id
  samp$area <- polybuff_area
  newtable<-rbind(newtable,samp)
}
newtable<-newtable[-c(1),] #the first row was the temp row

# convert to centroid points
samplept <- newtable
coordinates(samplept) <- c("x","y")
samplept@data$buffwidth <- sqrt(samplept@data$area/3.14)
head(samplept@data) #just checking

# finally... we create the comparison area
# size of the sample area is the same as the input polygons
# buffer around the points
compareArea <- gBuffer(samplept, byid=TRUE, width=samplept@data$buffwidth) # I think 0.01 degree is about 1km... just guessing
proj4string(compareArea)<-projinfo
# save as a new shapefile
writeOGR(compareArea, dsn = ".", layer="compareArea", driver = "ESRI Shapefile", overwrite_layer=T)

# plot = just to check
plot(polybuff)
plot(samplept, col="red", add=T)
plot(poly, col="green", add=T)
plot(line, col="grey", add=T)
plot(compareArea, col="blue", add=T)