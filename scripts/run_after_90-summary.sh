#!/bin/bash

cat <<'EOF'

mac-bootstrap post-install checklist

1. Sign in to Bitwarden, Cursor, Claude Code, and Codex with accounts approved by your employer.
2. Grant AeroSpace Accessibility permission in System Settings if AeroSpace is permitted.
3. Add employer-provided SSH or certificate settings to ~/.ssh/config.local.
4. Confirm the Git identity inside your configured work directory before committing.
5. Follow project-owned Go, Node, package-manager, and internal build-tool versions.
EOF
