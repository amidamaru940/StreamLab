#!/bin/sh
# Prints v5 transcripts for the same situations as Tests/main.swift (F1 comparison).
set -eu
cd "$(dirname "$0")/../.."
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
for f in Simulation CameraCueGate ConversationLibrary; do git show 1291a07:StreamLab/$f.swift > "$TMP/$f.swift"; done
swiftc -module-cache-path "$TMP/cache" "$TMP/Simulation.swift" "$TMP/CameraCueGate.swift" "$TMP/ConversationLibrary.swift" Tests/v5/main.swift -o "$TMP/v5"
"$TMP/v5"
