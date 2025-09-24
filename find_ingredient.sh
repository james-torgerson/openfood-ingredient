#!/usr/bin/env bash
set -euo pipefail # for script safety

# input variable set-up
INGREDIENT=""
DATA_DIRECTORY=""
CSV=""

# usage/help
usage() {
	echo "Usage $0 -i \"<ingredient>\" -d /path/to/folder"
	echo " -i ingredient to search for"
	echo " -d folder containing products.csv"
	echo " -h show help"
}

while getopts ":i:d:h" opt; do
	case "$opt" in
		i) INGREDIENT="$OPTARG" ;;
		d) DATA_DIRECTORY="$OPTARG" ;;
		h) usage; exit 0 ;;
		*) usage; exit 1 ;;
	esac
done

# validate inputs
[ -z "$INGREDIENT:-" ] && usage && exit 1
[ -z "$DATA_DIRECTORY:-" ] && usage && exit 1

CSV="$DATA_DIRECTORY/products.csv"
[ -s "$CSV" ] || { echo "ERROR: $CSV not found or empty." >&2; exit 1; }

# check csvkit tools
for cmd in csvcut csvgrep csvformat; do
	command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd not found. Please install csvkit." >&2; exit 1; }
done


# actual code pipeline
tmp_matches="$(mktemp)"
csvcut -t -c ingredients_text,product_name,code "$CSV" \
| csvgrep -c ingredients_text -r "(?i)${INGREDIENT}" \
| csvcut -c product_name,code \
| csvformat -T \
| tail -n +2 \
| tee "$tmp_matches"

N=$(wc -l < "$tmp_matches")
echo "-----"
echo "found ${N} product(s) containing: \"${INGREDIENT}\""

# cleanup
rm -f "$tmp_matches"
