#!/bin/bash

set -eu
set -o pipefail

if ! command -v fnm >/dev/null 2>&1; then
  printf '%s\n' 'fnm is not available after package installation.' >&2
  exit 1
fi

eval "$(fnm env --shell bash)"
fnm install --lts --use --corepack-enabled
node_version="$(fnm current)"
fnm default "$node_version"

if command -v corepack >/dev/null 2>&1; then
  corepack enable
else
  npm install --global corepack
  corepack enable
fi
