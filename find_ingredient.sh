# find_ingredient.sh
#!/usr/bin/env bash

set -euo pipefail # for safer bash

INGREDIENT=""
DATA_DIRECTORY=""
CSV=""

usage() {
	echo "Usage: $0 -i \"<ingredient>\" -d /path/to/folder"
	echo " -i ingredient to search for; case-insensitive"
	echo " -d folder containing products.csv"
	echo " -h show help"
}

# Getopts
while getopts ":i:d:h" opt; do
	case "$opt" in
		i) INGREDIENT="$OPTARG" ;;
		d) DATA_DIRECTORY="$OPTARG" ;;
		h) usage; exit 0 ;;
		*) usage; exit 1 ;;
	esac
done

# Validate inputs
[ -z "${INGREDIENT:-}" ] && usage && exit 1
[ -z "${DATA_DIR:-}" ] && usage && exit 1

CSV="$DATA_DIR/products.csv"
[ -s "$CSV" ] || { echo "ERROR: $CSV not found or empty." >&2; exit 1; }

# Check csvkit tools
for cmd in csvcut csvgrep csvformat; do
	command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd not found. Please install csvkit." >&2; exit 1; }
done

# Normalize Windows CRs (if any) into a temp file to avoid parsing issues
tmp_csv="$(mktemp)"
tr -d '\r' < "$CSV" > "$tmp_csv"

# Pipeline:
tmp_matches="$(mktemp)"
csvcut -t -c ingredients_text,product_name,code "$tmp_csv" | csvgrep -c ingredients_text -r "(?i)${INGREDIENT}" | csvcut -c product_name,code | csvformat -T | tail -n +2 | tee "$tmp_matches"

N="$(wc -l < \"$tmp_matches\" | tr -d ' ')"
echo "----"
echo "Found ${count} product(s) containing: \"${INGREDIENT}\""

# cleanup
rm -f "$tmp_csv" "$tmp_matches"
