#!/usr/bin/env bash
set -euo pipefail

src_dir=$1
thumb_dir=$2

mkdir -p "$thumb_dir"

while IFS= read -r -d '' src; do
    dst="$thumb_dir/thumb_${src##*/}.png"

    if [[ ! -f "$dst" || "$src" -nt "$dst" ]]; then
        magick "$src" -auto-orient -thumbnail x200 "$dst"
    fi
done < <(find "$src_dir" -maxdepth 1 \( -type f -o -type l \) -a \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 2>/dev/null | sort -z)
