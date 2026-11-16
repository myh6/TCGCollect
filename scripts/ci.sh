#!/bin/bash
# Runs every unit test through the fastlane `ci` lane, the same as CI does.
#
# Usage: scripts/ci.sh            (from anywhere in the repo)
#        SIMULATOR_ID=<udid> scripts/ci.sh   to pick a specific simulator
set -euo pipefail

cd "$(dirname "$0")/.."

bundle install --quiet
bundle exec fastlane ci
