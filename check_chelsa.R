#!/usr/bin/env Rscript
# STEP 6 (check): make sure the 21 downloaded CHELSA files are usable


suppressPackageStartupMessages(library(terra))
options(width = 200)

args <- commandArgs(trailingOnly = TRUE)
dir <- if (length(args) >= 1) args[1] else "chelsa_v21"

vars <- c(paste0("bio", 1:19), "cmi_mean", "sfcWind_mean")
files <- file.path(dir, paste0("CHELSA_", vars, "_1981-2010_V.2.1.tif"))

missing <- files[!file.exists(files)]
if (length(missing) > 0) stop("Missing files:\n", paste(missing, collapse = "\n"))

r <- lapply(files, rast)
ref <- r[[1]]
for (i in seq_along(r)) {
  if (!compareGeom(ref, r[[i]], stopOnError = FALSE)) stop("Grid differs for ", vars[i])
}
clim <- rast(r)
names(clim) <- vars
cat("All 21 layers open, same grid:", ncol(clim), "x", nrow(clim), "pixels, resolution",
    signif(res(clim)[1], 6), "degrees\n")
cat("Extent:", paste(round(as.vector(ext(clim)), 4), collapse = ", "), "\n\n")

places <- data.frame(
  place = c("Auckland", "Christchurch", "Suva (Fiji)", "Apia (Samoa)", "Paris", "Manila", "Brisbane"),
  lon   = c(174.76, 172.64, 178.44, -171.76, 2.35, 121.0, 153.03),
  lat   = c(-36.85, -43.53, -18.14, -13.83, 48.85, 14.6, -27.47))
vals <- extract(clim, vect(places[, c("lon", "lat")], geom = c("lon", "lat"), crs = "EPSG:4326"))
out <- cbind(place = places$place, round(vals[, c("bio1", "bio5", "bio6", "bio12", "cmi_mean", "sfcWind_mean")], 2))
cat("Values at test locations (bio1 = mean annual temp degC, bio5/bio6 = max/min temp,\n",
    "bio12 = annual rainfall mm, cmi = moisture index, sfcWind = mean wind m/s):\n", sep = "")
print(out, row.names = FALSE)

if (any(is.na(vals$bio1))) {
  cat("\nWARNING: some test locations have no data - send this output to Claude\n")
} else {
  cat("\nAll test locations have data, including NZ and the Pacific.\n")
}
