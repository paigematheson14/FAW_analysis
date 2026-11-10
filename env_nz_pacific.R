#!/usr/bin/env Rscript
#builds one table for all of the environmental data (climate, land cover, crops) on the CHELSA 30 arc-sec grid for both the sampling locations and NZ + Pacific islands (target area for GO). This will be used to fit GO model which can be projected onto the NZ and PAcific. 

library(terra)
terraOptions(tempdir = "/nesi/nobackup/ga03488/tmp")

env <- "/nesi/nobackup/ga03488/FAW_data/02_environmental_data"
out <- file.path(env, "02_raster_FAW/env_nz_pacific")
dir.create(out)

#load the environmental data from each of the three datasets
#climate: 21 CHELSA layers (use this as the reference grid)
vars <- c(paste0("bio", 1:19), "cmi_mean", "sfcWind_mean")
chelsa <- rast(file.path(env, "01_FAW/chelsa_v21", paste0("CHELSA_", vars, "_1981-2010_V.2.1.tif")))
names(chelsa) <- vars

#land cover: 6 Copernicus % cover layers at 100 m (255 = no data)
lc_layers <- c("Crops", "Tree", "Grass", "Shrub", "BuiltUp", "Bare")
lc <- rast(file.path(env, "01_FAW/landcover_raw",
  paste0("PROBAV_LC100_global_v3.0.1_2019-nrt_", lc_layers, "-CoverFraction-layer_EPSG-4326.tif")))
NAflag(lc) <- 255
names(lc) <- paste0("lc_", lc_layers)

#crops: 6 SPAM harvested area layers (ha per 5 arc-min cell) -> fraction of cell area; no crop = 0
crops <- c("MAIZ", "SORG", "RICE", "WHEA", "COTT", "SUGC")
spam <- rast(file.path(env, "01_FAW/spam_raw", paste0("spam2020_V2r2_global_H_", crops, "_A.tif")))
spam <- ifel(is.na(spam) | spam < 0, 0, spam) / cellSize(spam, unit = "ha")
names(spam) <- paste0("spam_", crops)

#This is a function where you can give it any rectangle and it returns all 33 of the layers for that area on the 1km CHELSA grid. The samples and the target map both go through it in order to make them consistent 
env_for <- function(e) {
  clim <- crop(chelsa, e, snap = "out")
  lc_e <- resample(crop(lc, ext(clim), snap = "out"), clim, method = "average")
  sp_e <- resample(crop(spam, ext(clim), snap = "out"), clim, method = "near")
  mask(c(clim, lc_e, sp_e), clim[[1]]) # this part removes every pixel where the first climate layer is empty - i.e., the ocean. Without it, the ocean gets land-cover and crop values of 0. 
}

#give every sampling location from the public data it's 33 values and save them as a csv file
pts <- read.csv(file.path(env, "metadata_FAW.csv"))
pts <- pts[!is.na(pts$Lat), ] # we are missing coordinates for 4 chinese samples - go back and fix this paige
vals <- do.call(rbind, lapply(seq_len(nrow(pts)), function(i) {
  p <- vect(pts[i, ], geom = c("Lon", "Lat"), crs = "EPSG:4326")
  extract(env_for(ext(buffer(p, 5000))), p, ID = FALSE)
}))
write.csv(cbind(pts, vals), file.path(out, "sample_env.csv"), row.names = FALSE)
print(pts[!complete.cases(vals), c("pop_code", "country", "locality")])   # locations with missing values

#target area: one box per island group (lon min, lon max, lat min, lat max); Fiji crosses 180 so has two boxes. if we want to add another area later (e.g., chatham islands), just need to add another line in the same format. Double check with Ang & Manpreet what islands we want to include
boxes <- list(
  NZ            = c( 166.0,  179.0, -47.5, -34.0),
  NewCaledonia  = c( 163.0,  169.0, -23.0, -19.5),
  Vanuatu       = c( 166.0,  170.5, -20.5, -13.0),
  Fiji_west     = c( 176.8,  180.0, -21.0, -15.5),
  Fiji_east     = c(-180.0, -178.0, -21.0, -15.5),
  Tonga         = c(-176.3, -173.5, -22.5, -15.5),
  Samoa         = c(-172.9, -171.3, -14.2, -13.4),
  CookIslands   = c(-160.5, -157.0, -22.2, -18.5))

target <- list()
for (a in names(boxes)) {
  x <- env_for(ext(boxes[[a]]))
  writeRaster(x, file.path(out, paste0("target_env_", a, ".tif")), overwrite = TRUE)
  target[[a]] <- cbind(area = a, as.data.frame(x, xy = TRUE, na.rm = TRUE))
}
saveRDS(do.call(rbind, target), file.path(out, "target_env.rds"))
