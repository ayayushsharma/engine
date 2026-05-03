#!/usr/bin/env bash
set -euo pipefail

rm 256x256 128x128 64x64 32x32 16x16 8x8 -r || true

ORIG_DIR="./original"
SIZE_FILE="$ORIG_DIR/size.txt"

if [[ ! -f "$SIZE_FILE" ]]; then
    echo "Error: $SIZE_FILE not found"
    exit 1
fi

orig_size=$(<"$SIZE_FILE")

if ! [[ "$orig_size" =~ ^[0-9]+$ ]]; then
    echo "Error: size.txt must contain an integer"
    exit 1
fi

sizes=()
current=$orig_size
while (( current > 8 )); do
    next=$(( current / 2 ))
    sizes+=("$next")
    current=$next
done

echo "Binning chain: $orig_size -> ${sizes[*]}"

process_image() {
    inroot="$1"
    outroot="$2"
    img="$3"

    rel="${img#$inroot/}"
    outpath="$outroot/$rel"

    mkdir -p "$(dirname "$outpath")"

    # skip non-images
    if ! magick identify "$img" >/dev/null 2>&1; then
        return 0
    fi

    magick "$img" -resize 50% "$outpath"
}

export -f process_image

prev_dir="$ORIG_DIR"

for size in "${sizes[@]}"; do
    next_dir="./${size}x${size}"
    mkdir -p "$next_dir"

    echo "Generating $next_dir from $prev_dir"

    mapfile -t images < <(find "$prev_dir" -type f ! -name "size.txt")

    parallel --bar process_image "$prev_dir" "$next_dir" {} ::: "${images[@]}"

    prev_dir="$next_dir"
done
