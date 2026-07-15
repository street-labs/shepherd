#!/usr/bin/env bash
# Wrapper: delegates to the real script in .pdeq, preserving all args and
# the shell-globbing context (BASH_SOURCE[0] resolves to the real script
# directory, so audit-coverage.py is found alongside it).
exec "$(cd "$(dirname "$0")" && pwd)/../.pdeq/scripts/audit-coverage.sh" "$@"
