#!/usr/bin/env bash
# Backward-compatible entry point for Tier A manuscript reproduction.
set -euo pipefail
cd "$(dirname "$0")/.."
exec bash analysis/run_manuscript_tier_a.sh "$@"
