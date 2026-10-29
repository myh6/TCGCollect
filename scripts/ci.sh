#!/bin/bash
# Runs every unit test: the AppCore and HoloCard packages' (swift test) and the app target's (TCGCollectTests on an iOS Simulator).
# The end-to-end tests skip themselves because E2E_BASE_URL and E2E_API_KEY aren't set here.
#
# Usage: scripts/ci.sh            (from anywhere in the repo)
#        SIMULATOR_ID=<udid> scripts/ci.sh   to pick a specific simulator
set -euo pipefail

cd "$(dirname "$0")/.."

# The app's Debug build reads Secrets.xcconfig. CI has none, so use the template's placeholder values.
# Never overwrite a real local one.
if [[ ! -f Secrets.xcconfig ]]; then
    echo "Secrets.xcconfig not found; using Secrets.example.xcconfig placeholders"
    cp Secrets.example.xcconfig Secrets.xcconfig
fi

echo "==> AppCore package tests"
swift test --package-path Packages/AppCore

echo "==> HoloCard package tests"
swift test --package-path Packages/HoloCard

echo "==> App unit tests"
if [[ -z "${SIMULATOR_ID:-}" ]]; then
    # The newest iOS runtime's first available iPhone, so the script doesn't depend on one device name.
    SIMULATOR_ID=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
ios = sorted((runtime for runtime in devices if ".iOS-" in runtime), key=lambda r: [int(p) for p in r.rsplit("iOS-", 1)[1].split("-")])
iphones = [d["udid"] for runtime in reversed(ios) for d in devices[runtime] if d["name"].startswith("iPhone")]
print(iphones[0] if iphones else "")
')
fi
if [[ -z "$SIMULATOR_ID" ]]; then
    echo "No available iPhone simulator found" >&2
    exit 1
fi

xcodebuild test \
    -project TCGCollect.xcodeproj \
    -scheme TCGCollect \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:TCGCollectTests \
    -derivedDataPath build/DerivedData \
    CODE_SIGNING_ALLOWED=NO
