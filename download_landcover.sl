#!/bin/bash
#SBATCH --job-name=lc_dl
#SBATCH --account=ga03488
#SBATCH --time=06:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --output=step7_download_%j.out

#download land cover from Copernicus (2019; 100 m): six "% cover" layers - crops, trees, grass, shrub, builtup, and bare

LC_DIR=/nesi/nobackup/ga03488/FAW_data/02_environmental_data/landcover_raw
mkdir -p "$LC_DIR"

#get the file list from Zenodo, keep the six layers, and download each one
#files already on disk at the right size are skipped; partial files are resumed
curl -sSL -f https://zenodo.org/api/records/3939050 | python3 -c "
import json, sys
for f in json.load(sys.stdin)['files']:
    for w in 'Crops Tree Grass Shrub BuiltUp Bare'.split():
        if '_' + w + '-CoverFraction-layer' in f['key']:
            print(f['key'], f['size'], f['links']['self'])
" | while read -r key size url; do
  f="$LC_DIR/$key"
  [ "$(stat -c %s "$f" 2>/dev/null)" = "$size" ] && continue
  curl -sSL -f --retry 10 --retry-delay 30 -C - -o "$f" "$url"
done
