# STEP 1 - for cleaning all objects
# rm(list = ls())

# STEP 2 # set working directory
## this is how University IT System set up your workable space
setwd("C:/Users/xxxxx/Documents") # replace xxxxx with your NetID, for BSLC018 labe computer users
setwd("H://Documents")  # for vlab users

# STEP 3 # download data files for today
download.file("http://home.uchicago.edu/~cmaene/Rworkshop.zip", destfile = "Rworkshop.zip")
unzip("Rworkshop.zip")

# STEP 4 # move to the data directory
setwd("data")

# STEP 5 # what are in the directory?
dir()

#######################################################################################
##### Warm-up
##### packages: N.A.
#######################################################################################

# STEP 6 # what packages are uploaded with R start-up
(.packages())

# STEP 7 # what other packages are available
## (remember we can always add more packages by installing them..)
(.packages(all.available=TRUE))

# STEP 8 # get more information on packages on the machine/server
installed.packages()

# STEP 9 # wow - that was a lot! here is a better way - save the list of installed packages as data
pck <-installed.packages()
View(pck)
colnames(pck)

# STEP 10 # test to see if "rgdal" is in the first column, "package" name
"rgdal" %in% pck[,1]

# STEP 11 # found it? now, get the information about your "rgdal" package
index <- which(pck[,1]=="rgdal")
pck[index,]

# STEP 12 # install a package from a specified respository
install.packages("sp", repos='http://cran.us.r-project.org')

# STEP 13 # by the way, what is "sp" package?
packageDescription("sp")

# STEP 14 # to play in R, use these popular tutorial datasets
install.packages("spdep")
library("spdep")

# STEP 15 # get more information in View panel
library(help="spdep")

# STEP 16 # as most packages do, spdep comes with tutorial data, try Boston housing price data
data(boston)

# STEP 17 # there are many ways to look at a data frame object
summary(boston.c)
str(boston.c)
class(boston.c)
head(boston.c)
tail(boston.c)
View(boston.c) # opens data frame view window..

# STEP 18 # a-ha! this data has a special component - Longitude/X and Latitude/Y !
plot(boston.c$LON, boston.c$LAT)

# STEP 19 # Not pretty.. let's add colors, representing median housing value
cPalet <- colorRampPalette(c("red", "yellow", "green"))
cValue <- cPalet(12)[as.numeric(cut(boston.c$MEDV, breaks=12))]
plot(boston.c$LON, boston.c$LAT, col=cValue, pch=20)

#######################################################################################
##### Spatial Analysis - upload spatial data files
##### packages: sp, rgdal,
#######################################################################################

# STEP 20 # if you haven't installed rgdal, install it, or skip if you have.
install.packages("rgdal", repos="http://cran.us.r-project.org")

# STEP 21 # upload "sp"
library(sp)

# STEP 22 # create spatial point data from XY (GPS-like) table
GPSdata <- read.csv("GPS.csv")
class(GPSdata)              # data frame

# STEP 23 # grab x (longitude) and y (latitude) values to create a SpatialPoints object
GPSpt1 <- SpatialPoints(GPSdata[,c("x","y")])
class(GPSpt1)               # SpatialPoints class - no attributes
summary(GPSpt1)

# STEP 24 # GPS data comes with species name field - add the data to create a SpatialPointsDataFrame object
GPSpt2 <- SpatialPointsDataFrame(GPSdata[,c("x","y")], GPSdata, match.ID=FALSE)
summary(GPSpt2)             # SpatialPointsDataFrame - with attributes

# STEP 25 # add one more information - coordinate referemce system (CRS) information
proj4string(GPSpt2) <- CRS("+proj=longlat +datum=NAD83")
summary(GPSpt2)             # SpatialPointsDataFrame - with attributes & SRS

# STEP 26 # another way of looking at a complex object (NOT recommended for data.frame/matrix)
GPSpt2

# STEP 27 # add rgdal package - R's interface for GDAL/OGR
library(rgdal)

# STEP 28 # see what formats are available
ogrDrivers()   # show "writable" drivers only, but some drivers are available for reading.
gdalDrivers()

# STEP 29 # check data wihtout loading
ogrInfo("sample.kml", layer="Paths")
GDALinfo("elevation.asc")

# STEP 30 # read shapefiles with GDAL's OGR
roads <- readOGR(dsn="roads.shp", layer="roads", verbose=TRUE)
class(roads)                # see what consists of the roads object
summary(roads)              # get more infor - OGR reads .prj/projection info

# STEP 31 # SP objects are complex
class(roads)                               # class of roads
str(roads)                                 # what's in roads, SpatialLinesDataFrame?

# STEP 32 # 4 slots that comprise of roads are: data, lines, bbox, proj4string

# STEP 33 # let's drill-down the lines slot object -
class(roads@lines)                         # class of roads' lines
length(roads@lines)                        # how many are in the lines list?
class(roads@lines[[1]])                    # what is the 1st object in the lines' list?
class(roads@lines[[1]]@Lines)              # what is the Lines object?
length(roads@lines[[1]]@Lines)             # how many are in the Line's list? - always only one
roads@lines[[1]]@Lines[[1]]                # so, what's in this list object?
class(roads@lines[[1]]@Lines[[1]]@coords)  # class of the vertex coordinates

# STEP 34 # we don't usugally care about individual vertex coordinates but it is possible to access/read.
## get the coordinates of line vertexes of the first line
roads@lines[[1]]@Lines[[1]]@coords
## get the coordinates of line vertexes of the 50th line
roads@lines[[50]]@Lines[[1]]@coords

# STEP 35 # read grid/raster data with GDAL
raster <- readGDAL("elevation.asc")
class(raster)             # SpatialGridDataFrame

# STEP 36 # plot to see it
plot(raster)              # not what I expected

# STEP 37 # often, we use "raster" packages' rasterlayer class, not sp' spatialgrid
library(raster)
raster <- raster("elevation.asc")
plot(raster)              # better..
# STEP 38 # image(raster)             # alternative

# STEP 39 # add GPS points and road lines to the raster plot
plot(roads, col="black", add=T)
plot(GPSpt2,  col="blue", add=T)

# STEP 40 # once opening up a lot of data, I can't keep track of objects I loaded..
ls()

#######################################################################################
##### Spatial Analysis - Overlay
##### packages: rgeos
##### Let's try classic GIS functions - buffer & overlay - with rgeos. In this scenario,
##### we will identify apartments within a half-mile distance from the prefered train
##### stations. For overlay/intersect/spatial-join selections, I am trying four different
##### methods using different tools.
#######################################################################################

# STEP 41 # skip below if installed previously
install.packages("rgeos", repos="http://cran.us.r-project.org")

# STEP 42 # add rgeos
library(rgeos)

# STEP 43 # upload a shapefile
sts <- readOGR(dsn="CTAbrown.shp", layer="CTAbrown", verbose=FALSE)

# STEP 44 # check spatial/coodinate reference system (srs/crs) information of "sts"
## because the subsequent buffer unit will be determined by it!
proj4string(sts)           #  unit=US feet (us-ft). Hard to tell but it's Illinois State Plane CS, Zone East.

# STEP 45 # create buffer - define half-mile (2640 ft) from the train stations
stsBuffer <- gBuffer(sts, width=2640)

# STEP 46 # overlay to find how many apartments fall in the train station buffer zones
apts <- readOGR(dsn=".", layer="apartments", verbose=FALSE)
proj4string(apts)           # in WGS84, unit=degree, well, we have a discrepancy in the two input data

# STEP 47 # reproject "apts" in the same CRS as "sts" - rgdal's spTransform will help us!
apts <-spTransform(apts, CRS(proj4string(sts)))

# STEP 48 # what is the current CRS/projection of apartments?
proj4string(apts)

# STEP 49 # method 1: using normal subset with sp objects! kinda cool, I found..
aptsSubset <- apts[stsBuffer,]

class(aptsSubset)           # SpatialPointsDataFrame
head(aptsSubset@data)
plot(stsBuffer)
plot(aptsSubset, col="red", pch=17, add=TRUE)

# STEP 50 # method 2: using sp's over
aptsOverIndex <-over(apts,stsBuffer)
aptsOver      <-apts[!is.na(aptsOverIndex),]

class(aptsOver)             # SpatialPointsDataFrame

# STEP 51 # method 3: using rgeos'gIntersection
aptsInside  <-gIntersection(apts, stsBuffer)
aptsOutside <-gDifference(apts, stsBuffer)
## rgeos' gInteresection returns SpatialPoints objects (without data frame/attributes)
class(aptsInside)

# STEP 52 # method 4: using rgeos' gIntersects - it returns a logical (T/F) matrix
# STEP 53 # which we can use then to create a new SpatialPointsDataFrame (SPDF) object
aptsInsideTF<-gIntersects(apts, stsBuffer, byid=TRUE)
aptsInside  <-apts[as.vector(aptsInsideTF),]  # note: turn matrix to vector for subsetting
class(aptsInside)            # SpatialPointsDataFrame

# STEP 54 # plot to see if worked
plot(stsBuffer, axes=TRUE)
plot(sts, pch=19, cex=0.5, add=TRUE)
plot(aptsInside, col="red", pch=8, add=TRUE)
plot(aptsOutside, col="blue", pch=3, add=TRUE)
legend("topright", legend=c("CTA stations","Inside","Outside"), cex=0.8, bty="n", lwd=2, col=c("black","red","blue"), pch=c(19,8,3), lty=c(NA,NA,NA))
## add a label - Apartment IDs
labelxy <- coordinates(aptsInside)
text(labelxy,labels=aptsInside@data$APTID, cex=0.8)
## add a title
title(main="Apartments Selected \nwithin 1/2 mile from CTA Brown")

#######################################################################################
##### Spatial Analysis - Distance
##### packages: rgeos
##### Since we have an appropriate datasets, let's calculate distance with rGEOS -
##### for each of the selected apartment, we want to know the closest CTA Brown station
##### and the distance from it
#######################################################################################

# STEP 55 # rgeos' gDistance calculates cartesian/Euclidean minimum distance.
## for geodesic distance - consider SDMTools (vincenty method) or other tools.
## before calculating, make sure both input data are in the same projection/CRS
proj4string(sts)
proj4string(aptsInside)

# STEP 56 # calculate distance to the nearest CTA Brown stations
dist <- gDistance(aptsInside, sts, byid=TRUE)

# STEP 57 # get the nearest station ID and the distance value (in US-feet)
distMinNearSts <- apply(dist, 2, function(x) which.min(x))
distMinValue   <- apply(dist, 2, function(x) min(x))
distancedata   <- cbind(aptsInside@data, distMinNearSts, distMinValue)
distancedata  # check the result

#######################################################################################
##### Spatial Analysis - Choropleth/thematic mapping
##### packages: RColorBrewer, ckassInt, maptools
##### let's create some maps - choropleth & dot density maps. In addition to the previous
##### two libraries, sp and rgdal, I am adding a color palette library, RColorBrewer -
##### a must have library for pretty cartographic works. We will also load classInt to
##### divide values into classes and maptools to create a dot density map
#######################################################################################

# STEP 58 # skip below if installed previously
install.packages(c("RColorBrewer","classInt","maptools"), repos="http://cran.us.r-project.org")
library(RColorBrewer)
library(classInt)
library(maptools)

# STEP 59 # here are the available color palette
par(mar = c(1, 3, 1, 1))
display.brewer.all()

# STEP 60 # Chicago census tracts
tracts <-readOGR(dsn=".", layer="tracts", verbose=TRUE)

# STEP 61 # define equal-frequency interval class
age_under5 <- tracts@data$AGEU5
nclr <- 5
colors <- brewer.pal(nclr, "YlOrBr")
class <- classIntervals(age_under5, nclr, style="quantile")
colorcode <- findColours(class, colors)

# STEP 62 # plot a choropleth map
plot(tracts, col = colorcode)
title(main = "Age Under 5: Quantile (Equal-Frequency)")
legend("topright", legend=names(attr(colorcode, "table")), fill=attr(colorcode, "palette"), cex=0.6, bty="n")

# STEP 63 # prepare for a dot density map
hispanic <- tracts@data$HISPANIC
dotper <- hispanic/500
dothispanic <- dotsInPolys(tracts, as.integer(dotper), f="random")
plot(tracts)
plot(dothispanic, col="brown", pch=19, cex=0.2, add=TRUE)
title(main="Dot Density Map: dot=500 persons")

# STEP 64 # add dots for black & a legend
black <- tracts@data$BLK
dotper2 <- black/500
dotblack <- dotsInPolys(tracts, as.integer(dotper2), f="random")
plot(dotblack, col="blue", pch=19, cex=0.2, add=T)
legend("bottomleft", legend = c("Hispanic", "Black"), fill=c("brown", "blue"), bty="n")

#######################################################################################
##### Spatial Analysis - Image analysis, map/matrix algebra with imagery
##### packages: raster
##### Satelite imagery has been used for many analyses, such as landuse, vegetation,
##### crop growth, flood zone, etc. Here, we will create NDVI (Normalized Difference
##### Vegetation Index) data from Landsat 7 image. Reference on NDVI is below:
##### https://en.wikipedia.org/wiki/Normalized_Difference_Vegetation_Index
#######################################################################################

# STEP 65 # skip below if installed previously
install.packages(c("raster"), repos="http://cran.us.r-project.org")
library(raster)

# STEP 66 # load the landsat7 GeoTiff file
landsat <- raster('landsat7.tif')
# STEP 67 # look at the object
landsat

# STEP 68 # since landsat is not a single band/channel image, let's treat as RasterBrick object
landsat <- brick('landsat7.tif')
# STEP 69 # look at the object again
landsat

# STEP 70 # just for fun, extract one band from the rasterBrick one at a time
landsatB1 <-raster(landsat[[1]]) # visible blue
landsatB2 <-raster(landsat[[2]]) # visible green
landsatB3 <-raster(landsat[[3]]) # visible red
landsatB4 <-raster(landsat[[4]]) # Near Infrared
landsatB5 <-raster(landsat[[5]]) # short-wave Infrared
landsatB7 <-raster(landsat[[6]]) # short-wave Infrared
## notice (above): I omitted B6 (emitted thermal, not reflected)

# STEP 71 # plot with color
plotRGB(landsat, r=3, g=2, b=1)  # natural color, like a photograph
plotRGB(landsat, r=4, g=3, b=2)  # vegetation-enhanced

# STEP 72 # I noticed plotRGB mess up graphics device - close current to start fresh
graphics.off()    # dev.off()

# STEP 73 # let's try map (or matrix) algebra with the stackup layers
## NDVI: normalized difference vegetation index is calculated using visible-red and near-infrared
ndvi <- (landsat[[4]] - landsat[[3]]) / (landsat[[4]] + landsat[[3]])
plot(ndvi) # higher value means more vegetation, green area

# STEP 74 # with different color, specified class/interval..
library(RColorBrewer)
colors <- brewer.pal(10, "PiYG")
plot(ndvi, breaks=c(-0.5,-0.4,-0.3,-0.2,-0.1,0,0.1,0.2,0.3,0.4,0.5), col=colors)

# STEP 75 # realized that our unit is not decimal degree, but meters (UTM projection)
crs(ndvi)

# STEP 76 # reproject the NDVI raster layer
ndvi_wgs84 <- projectRaster(ndvi, crs="+init=epsg:4326")
plot(ndvi_wgs84)

# STEP 77 # save as GeoTif
writeRaster(ndvi_wgs84, "ndvi_wgs84.tif", format="GTiff")

#######################################################################################
##### Spatial Analysis - Interpolation
##### packages: rgdal, raster, gstat
##### Raster analysis examples - based on weather station records, we (1) interpolate to
##### create precipitation surface map and then (2) summarize the value by state to
##### calculate the wettest and driest states. We will add raster and gstat packages.
#######################################################################################

# STEP 78 # skip below if installed previously
install.packages(c("gstat"), repos="http://cran.us.r-project.org")
library(gstat)

# STEP 79 # Part 1: interpolate to create precipitation surface map
weathersts <-readOGR(dsn=".", layer="weatherst", verbose=FALSE)

# STEP 80 # create a regular interval (1-degree) grid
ext <-bbox(weathersts)
grid <- expand.grid(x=seq(ext[1,1],ext[1,2],by=1),y=seq(ext[2,1],ext[2,2],by=1))
coordinates(grid)<-c("x","y")   # turn grid1 to a spatial point object
proj4string(grid) <- proj4string(weathersts)

# STEP 81 # idw estimates/interpolates values for all regularly spaced grid cells, based on input
idw <- idw(PYR ~ 1, weathersts, grid, idp=2)

# STEP 82 # the output is spatialPointsDataFrame
idw

# STEP 83 # transfer the result into the blank raster grid
idwgrid <- rasterFromXYZ(as.data.frame(cbind(grid$x, grid$y, idw@data$var1.pred)))

# STEP 84 # add state lines
states <- readOGR(dsn=".", layer="states48", verbose=FALSE)
plot(idwgrid)
plot(states, add=T)

# STEP 85 # Part 2: summarize the interpolated values by state to find the driest and wettest states
meanPYR <- extract(idwgrid, states, fun=mean)
states@data<-cbind(states@data,meanPYR)
nclr<-11
color<-brewer.pal(nclr, "RdYlGn")
class <- classIntervals(states@data$meanPYR, nclr, style="quantile")
colorcode<-findColours(class, color)
plot(states, col=colorcode, axes=TRUE)

# STEP 86 # show the top 5 driest states
sort<-states@data[order(states@data$meanPYR),]
head(sort)

# STEP 87 # show the top 5 wettest states
sort<-states@data[order(states@data$meanPYR, decreasing=TRUE),]
head(sort)

#######################################################################################
##### Spatial Analysis - EXTRA: how to loop through features and plot each
##### packages: rgdal
##### looping through the list of 48 contiguous states (plus DC) and map the 
##### election results by county.
##### OUTPUT - see the "data" folder - after running this, should see 49 new images/maps
#######################################################################################

library(rgdal)

# read data files
states <- readOGR(dsn="states48.shp", layer="states48", verbose=FALSE)
states <- states[order(as.numeric(states@data$STATEFP)), ] # order alphabetically
counties <- readOGR(dsn="2004_Election_Counties.shp", layer="2004_Election_Counties")

for (i in 1:49) {
  keep <- states[i,]
  # mapping related info
  statefips <- as.character(keep@data[1, 1])
  statesname <- as.character(keep@data[1, 5])
  statename <- as.character(keep@data[1, 6])
  titlename <- c("County Election Map : ", statename)
  pngname <- paste(c("statemap", statesname, ".png"), collapse = "")
  countieskeep <- counties[(counties@data$STATE_FIPS %in% c(statefips)), ]  
  # plot each state 
  png(filename = pngname)
  plot(states, border = "grey", col = "#FFFFFF", xlim = c(bbox(keep[, ])[1,1], bbox(keep[, ])[1, 2]), ylim = c(bbox(keep[, ])[2, 1], bbox(keep[,])[2, 2]))
  plot(countieskeep, col = (countieskeep@data$Bush_pct > 50) + 1, add = T)
  legend("bottomleft", legend = c("< 50%", "> 50%"), fill = c("black", "red"), title = "% Bush", cex = 0.8)
  plot(keep, border = "grey", pch = 50, add = T)
  title(main = titlename)
  dev.off()
}

#######################################################################################
##### Finishing up..
#######################################################################################

# STEP 88 # optional: save objects so far
save.image("Rwokshop.RData")
# load("Rwokshop.RData) # to load the saved objects

# STEP 89 # optional: save your command history - .Rhistory file will be created/updated in your working directory
savehistory()

