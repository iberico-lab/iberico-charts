#!/usr/bin/env bash
# The four charts are released together with one version. This keeps every
# `version:` and every file:// dependency pin in charts/*/Chart.yaml the same.
#
#   hack/bump-version.sh 0.4.0     # set the version everywhere
#   hack/bump-version.sh --check   # fail if the charts disagree (CI)
set -euo pipefail
cd "$(dirname "$0")/.."

versions() {  # every chart version and local dependency pin, one per line
  for f in charts/*/Chart.yaml; do
    sed -n 's/^version: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$f"
    grep -B1 'repository: "file://' "$f" | sed -n 's/^ *version: *"\{0,1\}\([^"]*\)"\{0,1\}$/\1/p'
  done
}

if [ "${1:-}" = "--check" ]; then
  found=$(versions | sort -u)
  if [ "$(printf '%s\n' "$found" | wc -l)" -ne 1 ]; then
    echo "Chart versions disagree (run: make bump VERSION=x.y.z):"; printf '  %s\n' $found; exit 1
  fi
  echo "all charts at $found"; exit 0
fi

new=${1:?usage: hack/bump-version.sh <x.y.z> | --check}
[[ $new =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "not a version: $new (want x.y.z)"; exit 1; }
for f in charts/*/Chart.yaml; do
  # chart version, then each `version:` line directly above a file:// repository
  sed -i.bak -E "s/^version: .*/version: $new/" "$f"
  awk -v v="$new" '
    { lines[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        if (lines[i] ~ /^ *version: / && lines[i+1] ~ /repository: "file:\/\//) {
          sub(/version: .*/, "version: \"" v "\"", lines[i])
        }
        print lines[i]
      }
    }' "$f" > "$f.tmp" && mv "$f.tmp" "$f" && rm -f "$f.bak"
done
"$0" --check
echo "Next: move CHANGELOG.md's unreleased notes under [$new], and add docs/upgrading.md steps if anyone has to act."
