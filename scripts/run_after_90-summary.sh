#!/bin/bash

cat <<'EOF'

mac-bootstrap post-install checklist

1. Sign in to Cursor and Codex with accounts approved by your employer.
2. On personal machines, sign in to Bitwarden and Claude Code, and grant
   AeroSpace Accessibility permission in System Settings.
3. Add employer-provided SSH or certificate settings to ~/.ssh/config.local.
4. Put machine-local shell configuration in ~/.zshrc.local.
5. Confirm the Git identity inside your configured work directory before committing.
6. Follow project-owned Go, Node, package-manager, and internal build-tool versions.
EOF
