#!/bin/bash

PARENT_DIR=$(dirname $(cd "$(dirname "$0")"; pwd))
CI_DIR="$PARENT_DIR/ci/environment"
#CI_DIR=/tmp/travis

ODB_VERSION=${1:-"2.0.4"}
ODB_DIR="${CI_DIR}/orientdb-community-${ODB_VERSION}"
ODB_LAUNCHER="${ODB_DIR}/bin/server.sh"



echo "=== Initializing CI environment ==="
cd "$PARENT_DIR"
mkdir -p $CI_DIR

echo "--- Downloading OrientDB v${ODB_VERSION} ---"
wget -q -O "$CI_DIR/orientdb-community-${ODB_VERSION}.tar.gz" "http://www.orientechnologies.com/download.php?email=unknown@unknown.com&file=orientdb-community-${ODB_VERSION}.tar.gz&os=linux"

echo "--- Unpacking ---------------------"
tar xf $CI_DIR/orientdb-community-${ODB_VERSION}.tar.gz -C $CI_DIR

echo "--- Setting up --------------------"
chmod +x $ODB_LAUNCHER
chmod -R +rw "${ODB_DIR}/config/"
ODB_ADMIN="<users><user resources=\"*\" password=\"root\" name=\"root\"/></users>"
sed "s:^[ \t]*<users.*$:    $ODB_ADMIN:" -i ${ODB_DIR}/config/orientdb-server-config.xml
sed "s:^[ \t]*<\/users.*$:    <!-- \/users -->:" -i ${ODB_DIR}/config/orientdb-server-config.xml
sed "s:^handlers = .*$:handlers = java.util.logging.ConsoleHandler:" -i ${ODB_DIR}/config/orientdb-server-log.properties

echo "--- Starting server ---------------"
sh -c $ODB_LAUNCHER </dev/null &>/dev/null &

# Wait a bit for OrientDB to finish the initialization phase.
sleep 5
printf "=== The CI environment has been initialized ===\n"