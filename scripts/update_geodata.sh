#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-$REPO_DIR/.geodata-check}"

GEOSITE_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
GEOIP_URL="https://raw.githubusercontent.com/QiuSimons/geoip-moedove/refs/heads/main/geoip.dat"

calc_sha256() {
    local file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo "error: neither sha256sum nor shasum is installed" >&2
        return 1
    fi
}

main() {
    mkdir -p "$TARGET_DIR"
    echo "==> Verifying embedded geodata sources..."
    echo "    geosite.dat: $GEOSITE_URL"
    echo "    geoip.dat:   $GEOIP_URL"

    curl -fsSL --retry 3 --connect-timeout 15 -o "$TARGET_DIR/geosite.dat" "$GEOSITE_URL"
    curl -fsSL --retry 3 --connect-timeout 15 -o "$TARGET_DIR/geoip.dat" "$GEOIP_URL"

    for name in geosite.dat geoip.dat; do
        local file="$TARGET_DIR/$name"
        local size hash
        size="$(wc -c < "$file" | tr -d ' ')"
        hash="$(calc_sha256 "$file")"
        printf '    %-12s %8d bytes  sha256=%s\n' "$name" "$size" "$hash"
    done

    echo "==> OK. The luci-app-honk build embeds these files (HASH:=skip in luci-app-honk/Makefile)."
    echo "    Review size/hash above before a release; sizes exceeding ~50 MiB total may need a smaller geodata source."
}

main "$@"
