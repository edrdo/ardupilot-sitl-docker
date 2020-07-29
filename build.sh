#! /bin/bash

docker build --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" . -t flytrex/flyhawk-sitl-docker:latest
