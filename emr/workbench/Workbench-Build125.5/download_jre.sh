#!/bin/bash

rm -f jre13.tar.gz

if [ "$(uname)" == "Darwin" ]; then
  jre_os="mac"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  jre_os="linux"
fi

curl --insecure -L "https://api.adoptopenjdk.net/v2/binary/releases/openjdk13?openjdk_impl=hotspot&os=${jre_os}&arch=x64&release=latest&type=jre" -o jre13.tar.gz

rm -Rf jre
mkdir jre

tar xf jre13.tar.gz --strip-components=1 --directory jre
