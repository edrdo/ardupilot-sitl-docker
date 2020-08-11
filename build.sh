#! /bin/bash

set -e

urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

USE_HTTPS=false
if [ "$1" = "https" ]
then
  USE_HTTPS=true
  shift
fi

VERSION=Flyhawk
if [ -n "$1" ]
then
  VERSION=$1
  shift
fi

if [ -n "$1" ]
then
  echo "Usage: build.sh [https] [<Flyhawk_Vx.x>]"
  exit 1
fi

DOCKER_NAME=flytrex/flyhawk-sitl-docker:latest
if [ "$USE_HTTPS" = true ]
then
  read -p "Username for git: "
  HTTPS_USER=$(urlencode "$REPLY")
  read -s -p "Password for git: "
  HTTPS_PASS=$(urlencode "$REPLY")
  echo
  git ls-remote https://"$HTTPS_USER":"$HTTPS_PASS"@github.com/Flytrex/flytrex_ardupilot.git $VERSION > _git_branch_head.txt
  docker build --build-arg VERSION=$VERSION --build-arg USE_HTTPS=true --build-arg HTTPS_USER=$HTTPS_USER --build-arg HTTPS_PASS=$HTTPS_PASS . -t $DOCKER_NAME
else
  git ls-remote git@github.com:Flytrex/flytrex_ardupilot.git $VERSION  > _git_branch_head.txt
  docker build --build-arg VERSION=$VERSION --build-arg USE_HTTPS=false --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" . -t $DOCKER_NAME
fi

