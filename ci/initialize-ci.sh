#!/bin/bash

PARENT_DIR=$(dirname $(cd "$(dirname "$0")"; pwd))
CI_DIR="$PARENT_DIR/ci/environment"

ODB_VERSION=${1:-"2.0.3"}
ODB_DIR="${CI_DIR}/orientdb-community-${ODB_VERSION}"
ODB_LAUNCHER="${ODB_DIR}/bin/server.sh"

echo "=== Initializing CI environment ==="

cd "$PARENT_DIR"

echo "--- Downloading OrientDB v${ODB_VERSION} ---"