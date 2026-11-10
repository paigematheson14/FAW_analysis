#!/usr/bin/env Rscript
# STEP 6 (check): make sure the 21 downloaded CHELSA files are usable

library(terra)

dir <- "chelsa_v21"
vars <- c(paste0("bio", 1:19), "cmi_mean", "sfcWind_mean")
files <- file.path(dir, paste0("CHELSA_", vars, "_1981-2010_V.2.1.tif"))

#check all files exist and open together (rast() stops if the grids differ)
stopifnot(all(file.exists(files)))
clim <- rast(files)
names(clim) <- vars
print(clim)

#values at test locations (should have no NAs)
places <- data.frame(
  place = c("Auckland", "Christchurch", "Suva (Fiji)", "Apia (Samoa)", "Paris", "Manila", "Brisbane"),
  lon   = c(174.76, 172.64, 178.44, -171.76, 2.35, 121.0, 153.03),
  lat   = c(-36.85, -43.53, -18.14, -13.83, 48.85, 14.6, -27.47))
vals <- extract(clim, vect(places, geom = c("lon", "lat"), crs = "EPSG:4326"))
print(cbind(place = places$place, round(vals[, c("bio1", "bio5", "bio6", "bio12", "cmi_mean", "sfcWind_mean")], 2)))
