#!/bin/sh
set -eu
cd "$(dirname "$0")"
TEMP_BUILD=$(mktemp -d)
trap 'rm -rf "$TEMP_BUILD"' EXIT
swiftc -module-cache-path "$TEMP_BUILD/cache" StreamLab/Simulation.swift StreamLab/CameraCueGate.swift StreamLab/ConversationLibrary.swift Tests/main.swift -o "$TEMP_BUILD/engine-tests"
"$TEMP_BUILD/engine-tests"
