#!/bin/bash

set -eu
set -o pipefail

if ! command -v nvim >/dev/null 2>&1; then
  printf '%s\n' 'Neovim is not available after package installation.' >&2
  exit 1
fi

nvim --headless \
  "+Lazy! sync" \
  "+lua require('config.bootstrap').wait_for_installs()" \
  +qa
