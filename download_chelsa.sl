#!/bin/bash
#SBATCH --job-name=chelsa_dl
#SBATCH --account=ga03488
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --output=step6_download_%j.out

#Download the 21 global CHELSA v2.1 (1981-2010) climate layers

WORKDIR=${WORKDIR:-/nesi/nobackup/ga03488/FAW_data/02_environmental_data/01_FAW}
OUTDIR=${OUTDIR:-$WORKDIR/chelsa_v21} #this folder unless told otherwise
BASE=${BASE:-https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/climatologies/1981-2010/bio}

VARS="bio1 bio2 bio3 bio4 bio5 bio6 bio7 bio8 bio9 bio10 bio11 bio12 bio13 bio14 \
bio15 bio16 bio17 bio18 bio19 cmi_mean sfcWind_mean"

mkdir -p "$OUTDIR"
cd "$OUTDIR" || exit 1

#small function that asks the CHELSA server how big a file is without downloading it (used later to tell whether a download is complete)
remote_size () {
  curl -sIL "$1" | grep -i '^content-length' | tail -1 | awk '{print $2}' | tr -d '\r'
}

#test we can reach the chelsa database
echo "$(date +%T) - Checking connection to CHELSA"
if ! curl -sfI "$BASE/CHELSA_bio1_1981-2010_V.2.1.tif" > /dev/null; then
  echo "ERROR: cannot reach the CHELSA server from $(hostname)."
  echo "Compute nodes may not have internet. Run this in the Jupyter terminal instead:"
  echo "  nohup bash step6_download_chelsa.sl > step6_download.log 2>&1 &"
  exit 1
fi

#check how big the dl is
echo "$(date +%T) - Checking file sizes"
total=0
for v in $VARS; do
  s=$(remote_size "$BASE/CHELSA_${v}_1981-2010_V.2.1.tif")
  if [ -z "$s" ]; then echo "ERROR: $v not found on server"; exit 1; fi
  printf "  %-14s %6d MB\n" "$v" $((s / 1024 / 1024))
  total=$((total + s))
done
echo "  TOTAL          $((total / 1024 / 1024 / 1024)) GB"
echo "  Free space here:"
df -h "$OUTDIR" | tail -1

#download the clim data - can rerun this script because it will skip variables if they are already done (that's why the function at the start is good because it will be able to see if all of the data is there). 
failed=""
for v in $VARS; do
  f="CHELSA_${v}_1981-2010_V.2.1.tif"
  want=$(remote_size "$BASE/$f")
  have=$(stat -c %s "$f" 2>/dev/null || echo 0)
  if [ "$have" = "$want" ]; then
    echo "$(date +%T) - $v already complete, skipping"
    continue
  fi
  echo "$(date +%T) - Downloading $v"
  if [ "$have" -gt 0 ]; then
    curl -sS -f --retry 10 --retry-delay 30 -C - -o "$f" "$BASE/$f"
  else
    curl -sS -f --retry 10 --retry-delay 30 -o "$f" "$BASE/$f"
  fi
  have=$(stat -c %s "$f" 2>/dev/null || echo 0)
  if [ "$have" != "$want" ]; then
    echo "   resume did not work, downloading $v again from the start"
    rm -f "$f"
    curl -sS -f --retry 10 --retry-delay 30 -o "$f" "$BASE/$f"
    have=$(stat -c %s "$f" 2>/dev/null || echo 0)
  fi
  if [ "$have" != "$want" ]; then
    echo "   WARNING: $v is incomplete ($have of $want bytes)"
    failed="$failed $v"
  fi
done

if [ -n "$failed" ]; then
  echo ""
  echo "These files did not finish:$failed"
  echo "Just run this script again - it will resume them."
  exit 1
fi

#check the files open and give sensible values
echo ""
echo "$(date +%T) - All 21 files downloaded. Checking values..."
module purge > /dev/null 2>&1
module load R-Geo/4.3.2-foss-2023a > /dev/null 2>&1
Rscript "$WORKDIR/step6_check_chelsa.R" "$OUTDIR"

echo "$(date +%T) - Finished OK"
