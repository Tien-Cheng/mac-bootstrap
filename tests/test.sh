#!/bin/bash

set -eu
set -o pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

init_root="$(mktemp -d)"
init_root="$(cd "$init_root" && pwd -P)"
mkdir -p "$init_root/home"
chezmoi init \
  --source "$repo_root" \
  --config-path "$init_root/chezmoi.toml" \
  --destination "$init_root/home" \
  --no-tty \
  --promptChoice 'Machine profile=work' \
  --promptBool 'Install optional desktop applications=true' \
  --promptString 'Git author name=Bootstrap Test' \
  --promptString 'Git author email=bootstrap@example.invalid' \
  --promptString "Root directory for work repositories=$init_root/home/work"

rg -q 'profile = "work"' "$init_root/chezmoi.toml"
rg -q 'fullInstall = true' "$init_root/chezmoi.toml"
rg -q 'email = "bootstrap@example.invalid"' "$init_root/chezmoi.toml"

shellcheck "$repo_root/bootstrap.sh" "$repo_root"/scripts/*.sh "$repo_root"/scripts/*.sh.tmpl
zsh -n "$repo_root/dot_zshrc"

if find "$repo_root/dot_config/nvim" -name .git -print -quit | grep -q .; then
  printf '%s\n' 'Embedded Git repository found under the Neovim configuration.' >&2
  exit 1
fi

if rg -n --hidden -g '!.git/**' -g '!tests/**' \
  '(/Users/|protonmail\.com|IdentityFile|git@github\.com|ctx7sk-|tvly-|exaApiKey)' \
  "$repo_root"; then
  printf '%s\n' 'A machine-specific path, identity, host rewrite, or credential pattern was found.' >&2
  exit 1
fi

for profile_name in work personal; do
  test_root="$(mktemp -d)"
  test_root="$(cd "$test_root" && pwd -P)"
  render_home="$test_root/home"
  test_config="$test_root/chezmoi.toml"
  mkdir -p "$render_home"

  cat > "$test_config" <<EOF
[data]
profile = "$profile_name"
fullInstall = true
workRoot = "$render_home/work"

[data.git]
name = "Bootstrap Test"
email = "bootstrap@example.invalid"
EOF

  chezmoi \
    --source "$repo_root" \
    --destination "$render_home" \
    --config "$test_config" \
    apply --force --exclude scripts

  test -f "$render_home/.Brewfile"
  test -f "$render_home/.zshrc"
  test -f "$render_home/.gitconfig"
  test -f "$render_home/.config/git/work"
  test -f "$render_home/.config/nvim/init.lua"
  test -f "$render_home/.aerospace.toml"
  test -f "$render_home/.ssh/config"

  zsh -n "$render_home/.zshrc"
  git config --file "$render_home/.gitconfig" --list >/dev/null
  mkdir -p "$render_home/work/smoke"
  git init -q "$render_home/work/smoke"
  test "$(HOME="$render_home" git -C "$render_home/work/smoke" config user.email)" = bootstrap@example.invalid
  if HOME="$render_home" git config --global --get user.email >/dev/null 2>&1; then
    printf '%s\n' 'Git identity unexpectedly leaked into the global configuration.' >&2
    exit 1
  fi
  HOME="$render_home" ssh -G -T example.invalid -F "$render_home/.ssh/config" >/dev/null
  brew bundle list --all --file="$render_home/.Brewfile" >/dev/null
  uv run --python 3.12 python -c \
    'import pathlib, tomllib; tomllib.loads(pathlib.Path("'"$render_home/.aerospace.toml"'").read_text())'

  for required_item in cursor claude-code codex aerospace brave-browser bitwarden ghostty; do
    rg -q "cask \"$required_item\"" "$render_home/.Brewfile"
  done

  if [ "$profile_name" = work ]; then
    if rg -q 'cask "discord"' "$render_home/.Brewfile"; then
      printf '%s\n' 'Personal applications leaked into the work profile.' >&2
      exit 1
    fi

    nvim_log="$test_root/nvim.log"
    if ! XDG_CONFIG_HOME="$render_home/.config" \
      XDG_DATA_HOME="$test_root/data" \
      XDG_STATE_HOME="$test_root/state" \
      XDG_CACHE_HOME="$test_root/cache" \
        nvim --headless \
          "+Lazy! sync" \
          "+lua require('config.bootstrap').wait_for_installs()" \
          +qa > "$nvim_log" 2>&1; then
      cat "$nvim_log" >&2
      exit 1
    fi
    if rg -q 'Error in command line|Failed to run `config`|Neovim exited while' "$nvim_log"; then
      cat "$nvim_log" >&2
      exit 1
    fi
  else
    rg -q 'cask "discord"' "$render_home/.Brewfile"
    rg -q 'cask "orbstack"' "$render_home/.Brewfile"
  fi
done

printf '%s\n' 'All mac-bootstrap tests passed.'
