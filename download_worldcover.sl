#!/bin/bash
#SBATCH --job-name=wc_dl
#SBATCH --account=ga03488
#SBATCH --time=06:00:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --output=step7b_download_worldcover_%j.out

#download ESA WorldCover 2021 (10 m land cover) tiles covering the sampling locations and the NZ + Pacific boxes
#tiles are 3 x 3 degrees and named after their bottom-left corner (e.g. S39E174)

ENV=/nesi/nobackup/ga03488/FAW_data/02_environmental_data
WC_DIR=$ENV/01_FAW/worldcover_raw
BASE=https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map

mkdir -p "$WC_DIR"
cd "$WC_DIR"

#work out which tiles are needed: a small window round every sampling location + the island boxes (same boxes as step 8)
python3 - "$ENV/metadata_FAW.csv" > tiles.txt <<'EOF'
import csv, math, sys
boxes = [(166, 179, -47.5, -34), (163, 169, -23, -19.5), (166, 170.5, -20.5, -13), (176.8, 180, -21, -15.5),
         (-180, -178, -21, -15.5), (-176.3, -173.5, -22.5, -15.5), (-172.9, -171.3, -14.2, -13.4), (-160.5, -157, -22.2, -18.5)]
for r in csv.DictReader(open(sys.argv[1])):
    try:
        x, y = float(r['Lon']), float(r['Lat'])
    except ValueError:
        continue
    boxes.append((x - 0.1, x + 0.1, y - 0.1, y + 0.1))
tiles = set()
for x0, x1, y0, y1 in boxes:
    for lat in range(math.floor(y0 / 3) * 3, math.floor((y1 - 1e-9) / 3) * 3 + 1, 3):
        for lon in range(math.floor(x0 / 3) * 3, math.floor((x1 - 1e-9) / 3) * 3 + 1, 3):
            tiles.add(f"{'N' if lat >= 0 else 'S'}{abs(lat):02d}{'E' if lon >= 0 else 'W'}{abs(lon):03d}")
print('\n'.join(sorted(tiles)))
EOF

#download each tile; tiles already here are skipped; all-ocean tiles don't exist on the server and are just skipped
while read -r t; do
  f="ESA_WorldCover_10m_2021_v200_${t}_Map.tif"
  [ -f "$f" ] && continue
  curl -sS -f --retry 5 --retry-delay 30 -o "$f.part" "$BASE/$f" 2>/dev/null && mv "$f.part" "$f"
  rm -f "$f.part"
done < tiles.txt
