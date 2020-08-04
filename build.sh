#! /bin/bash

if [ $# -gt 1 ] 
then
  echo "Usage: build.sh <Flyhawk_Vx.x>"
  exit 1
fi

VERSION=Flyhawk
if [ $# -eq 1 ] 
then
  VERSION=$1
fi

docker build --build-arg VERSION=$VERSION --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" . -t flytrex/flyhawk-sitl-docker:latest
