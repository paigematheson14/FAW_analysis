#!/bin/bash
#SBATCH --job-name=chelsa_dl
#SBATCH --account=ga03488
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --output=step6_download_%j.out

#download the 21 global CHELSA v2.1 (1981-2010) climate layers, then check they open

WORKDIR=/nesi/nobackup/ga03488/FAW_data/02_environmental_data/01_FAW
BASE=https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/climatologies/1981-2010/bio

mkdir -p "$WORKDIR/chelsa_v21"
cd "$WORKDIR/chelsa_v21"

#files already on disk at the server's size are skipped; partial files are resumed
for v in bio{1..19} cmi_mean sfcWind_mean; do
  f="CHELSA_${v}_1981-2010_V.2.1.tif"
  want=$(curl -sIL "$BASE/$f" | grep -i '^content-length' | tail -1 | awk '{print $2}' | tr -d '\r')
  [ -n "$want" ] && [ "$(stat -c %s "$f" 2>/dev/null)" = "$want" ] && continue
  curl -sS -f --retry 10 --retry-delay 30 -C - -o "$f" "$BASE/$f"
done

#check the files open and give sensible values
module purge
module load R-Geo/4.3.2-foss-2023a
cd "$WORKDIR"
Rscript step6_check_chelsa.R
