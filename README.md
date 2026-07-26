# mac-bootstrap

Portable, profile-aware macOS setup built with Homebrew and chezmoi. The repository contains no credentials, SSH keys, authentication state, or employer-specific source-control assumptions.

## Before using it on a work Mac

Confirm that your employer permits Homebrew, public dotfiles, AI coding tools, third-party browsers, password managers, and window managers. Do not use this bootstrap to bypass MDM, network controls, or an approved internal setup process.

## First-day setup

Download the bootstrap to a local file so you can inspect it before execution:

```sh
curl -fsSLo /tmp/mac-bootstrap.sh \
  https://raw.githubusercontent.com/Tien-Cheng/mac-bootstrap/main/bootstrap.sh
less /tmp/mac-bootstrap.sh
bash /tmp/mac-bootstrap.sh --profile work --full
```

Preview the plan without changing anything:

```sh
bash /tmp/mac-bootstrap.sh --profile work --full --dry-run
```

The command asks for one policy confirmation, followed by Git author details and the root directory for work repositories. It then installs the shared toolchain and requested applications. Authentication is always manual.

Exit codes:

- `0`: complete success
- `1`: prerequisite or core-tool failure
- `2`: setup completed, but one or more optional applications were blocked or failed

## Profiles

The `work` profile includes the shared Go, Node, shell, Git, and Neovim toolchain. With `--full`, it also installs Cursor, Claude Code, Codex, AeroSpace, Brave, Bitwarden, and Ghostty.

The `personal` profile includes the same shared base and adds personal applications such as Discord, Firefox, Google Drive, IINA, Obsidian, OrbStack, Raycast, and Visual Studio Code.

## Git and SSH

The global Git configuration has no hosting-provider rewrite and no global identity. `user.useConfigOnly` prevents accidental commits with a guessed identity. The prompted identity is applied conditionally beneath the configured work root.

Employer-provided SSH, certificate, or internal Git configuration belongs in `~/.ssh/config.local`. This file is intentionally unmanaged.

## Project versions

The bootstrap installs a current Node LTS through fnm and a current Homebrew Go baseline. Project `.node-version`, `.nvmrc`, package-manager metadata, `go.mod`, Go toolchain directives, and employer tooling remain authoritative.

## Updating

After pulling repository updates, run:

```sh
chezmoi diff
chezmoi apply
```

Package scripts are change-triggered and idempotent. They install missing dependencies but do not upgrade unrelated packages automatically.

## Validation

```sh
./tests/test.sh
gitleaks git --redact .
```

CI renders both profiles in temporary home directories, validates the generated Brewfiles and TOML, lints shell configuration, scans Git history, and synchronizes LazyVim headlessly.
