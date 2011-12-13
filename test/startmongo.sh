#! /usr/bin/env sh

mkdir -p tmp/mongodb_data

/usr/local/mongodb/bin/mongod --config etc/mongod-dev.conf
