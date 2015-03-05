#!/bin/bash

PARENT_DIR=$(dirname $(cd "$(dirname "$0")"; pwd))
CI_DIR="$PARENT_DIR/ci/environment"

#CI_DIR=/tmp/travis
#mkdir -p $CI_DIR
#exit

ODB_VERSION=${1:-"2.0.4"}
ODB_DIR="${CI_DIR}/orientdb-community-${ODB_VERSION}"
ODB_LAUNCHER="${ODB_DIR}/bin/server.sh"

echo "=== Initializing CI environment ==="
echo $(which java)
echo $(which wget)

cd "$PARENT_DIR"

echo "--- Downloading OrientDB v${ODB_VERSION} ---"
wget "http://www.orientechnologies.com/download.php?email=unknown@unknown.com&file=orientdb-community-${ODB_VERSION}.tar.gz&os=linux" -O $CI_DIR/orientdb-community-${ODB_VERSION}.tar.gz
echo "--- Unpacking ---------------------"
tar xf $CI_DIR/orientdb-community-${ODB_VERSION}.tar.gz -C $CI_DIR
