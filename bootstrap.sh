#!/bin/bash

set -u
set -o pipefail

readonly REPOSITORY_URL="https://github.com/Tien-Cheng/mac-bootstrap.git"

profile=""
full_install=false
dry_run=false

usage() {
  cat <<'EOF'
Usage: bootstrap.sh --profile work|personal [--full] [--dry-run]

  --profile   Select work-safe or personal packages and configuration.
  --full      Install optional desktop applications and AI clients.
  --dry-run   Print the plan without changing the machine.
EOF
}

print_plan() {
  cat <<EOF
Profile: $profile
Full install: $full_install

Shared command-line tools:
  Homebrew, chezmoi, Git, delta, Neovim, LazyVim, Starship,
  zsh autosuggestions and syntax highlighting, fnm, Node LTS,
  pnpm, Go, ripgrep, fd, bat, eza, jq, yq, uv, lazygit,
  tree-sitter CLI, gitleaks, and shellcheck

Shared desktop resources:
  MesloLGS Nerd Font
EOF

  if [ "$full_install" = true ]; then
    cat <<'EOF'

Full-install applications:
  Cursor, Claude Code, Codex, AeroSpace, Brave, Bitwarden,
  Bitwarden CLI, and Ghostty
EOF
  fi

  if [ "$profile" = personal ] && [ "$full_install" = true ]; then
    cat <<'EOF'

Personal-only applications:
  BetterDisplay, Discord, Firefox, Google Cloud CLI, Google Drive,
  IINA, Obsidian, OrbStack, Raycast, and Visual Studio Code
EOF
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      [ "$#" -ge 2 ] || { usage >&2; exit 1; }
      profile="$2"
      shift 2
      ;;
    --full)
      full_install=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$profile" in
  work|personal) ;;
  *)
    printf '%s\n' '--profile must be work or personal.' >&2
    usage >&2
    exit 1
    ;;
esac

print_plan

if [ "$dry_run" = true ]; then
  printf '\nDry run complete. No changes were made.\n'
  exit 0
fi

if [ "$(uname -s)" != Darwin ]; then
  printf '%s\n' 'This bootstrap supports macOS only.' >&2
  exit 1
fi

printf '\nThis is a company-managed-device safety checkpoint.\n'
printf '%s\n' 'Confirm that your employer permits these tools and configurations.'
printf 'Type YES to continue: '
read -r approval
if [ "$approval" != YES ]; then
  printf '%s\n' 'Setup cancelled. No installation was started.'
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  printf '%s\n' 'Requesting Apple Command Line Tools installation.'
  xcode-select --install || true
  printf '%s\n' 'Complete the Apple installer, then run this command again.' >&2
  exit 1
fi

brew_bin="$(command -v brew 2>/dev/null || true)"
if [ -z "$brew_bin" ]; then
  printf '%s\n' 'Installing Homebrew from brew.sh.'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      brew_bin="$candidate"
      break
    fi
  done
fi

if [ -z "$brew_bin" ] || [ ! -x "$brew_bin" ]; then
  printf '%s\n' 'Homebrew installation did not produce a usable brew command.' >&2
  exit 1
fi

eval "$("$brew_bin" shellenv)"

if ! brew install chezmoi; then
  printf '%s\n' 'Failed to install chezmoi.' >&2
  exit 1
fi

full_value=false
if [ "$full_install" = true ]; then
  full_value=true
fi

source_location="${MAC_BOOTSTRAP_SOURCE:-$REPOSITORY_URL}"
if ! chezmoi init "$source_location" \
  --apply \
  --promptChoice "Machine profile=$profile" \
  --promptBool "Install optional desktop applications=$full_value"; then
  printf '%s\n' 'chezmoi initialization or a core setup step failed.' >&2
  exit 1
fi

failure_file="$HOME/.local/state/mac-bootstrap/optional-failures"
if [ -s "$failure_file" ]; then
  printf '\nSetup completed with optional installation failures:\n' >&2
  sed 's/^/  - /' "$failure_file" >&2
  printf '%s\n' 'Review employer policy or rerun chezmoi apply after resolving access.' >&2
  exit 2
fi

printf '\nBootstrap completed successfully.\n'
exit 0
