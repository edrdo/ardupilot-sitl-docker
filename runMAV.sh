#! /bin/bash

if [ $# -ne 3 ] 
then
  echo "Usage: runMAV.sh <system_id> <gcs_host> <gcs_port>"
  exit 1
fi

SYS_ID=$1
GCS_HOST=$2
GCS_PORT=$3
SCRIPTS_DIR=$(cd $(dirname $(which $0)); pwd)

echo "Running SITL simulation ..."
echo SYS_ID=$SYS_ID GCS_HOST=$2 GCS_PORT=$3
echo SIM_OPTIONS=$SIM_OPTIONS
docker run --rm -it \
  -v $SCRIPTS_DIR:/external \
  -p $GCS_HOST:$GCS_PORT:$GCS_PORT/tcp \
  -e "GCS_PORT=$GCS_PORT" \
  -e "SIM_OPTIONS=-m --target-system=$SYS_ID $SIM_OPTIONS" \
  --entrypoint "/external/entryPoint.sh" \
  flytrex/flyhawk-sitl-docker:latest $SYS_ID
exit $?
