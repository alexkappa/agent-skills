#!/usr/bin/env bash
# Usage: fixture-copy.sh <variant>   (none, or a directory under fixtures/variants/)
set -euo pipefail

root=$(cd "$(dirname "$0")/fixtures" && pwd)
variant=${1:?usage: fixture-copy.sh <variant>}

if [ "$variant" != none ] && [ ! -d "$root/variants/$variant" ]; then
  echo "unknown variant: $variant" >&2
  exit 2
fi

dir=$(mktemp -d)
cp -R "$root/billing-app/." "$dir"
if [ "$variant" != none ]; then
  cp -R "$root/variants/$variant/." "$dir"
  find "$dir" -name '*.fixture' | while read -r f; do mv "$f" "${f%.fixture}"; done
fi

git -C "$dir" init -q
git -C "$dir" add -A
git -C "$dir" -c user.name=fixture -c user.email=fixture@example.com commit -q -m "fixture"
echo "$dir"
