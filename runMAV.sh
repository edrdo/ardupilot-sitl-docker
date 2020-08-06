#! /bin/bash

if [ $# -lt 3 ] || [ $# -gt 4 ] 
then
  echo "Usage: runMAV.sh <system_id> <gcs_host> <gcs_port> [<optional_param_file>]"
  exit 1
fi

SYS_ID=$1
GCS_HOST=$2
if [ "$(uname)" == "Darwin" ]
then  # Mac OS X platform
  GCS_HOST="docker.for.mac.localhost"
fi
GCS_PORT=$3
if [ $# -eq 4 ]
then
  PARAM_FILE="--add-param-file=$4"
fi
SCRIPTS_DIR=$(cd $(dirname $(which $0)); pwd)

echo "Running SITL simulation ..."
echo SYS_ID=$SYS_ID GCS_HOST=$2 GCS_PORT=$3
echo SIM_OPTIONS=$SIM_OPTIONS
docker run --rm -it \
  -v $SCRIPTS_DIR:/external \
  -p $GCS_HOST:$GCS_PORT:$GCS_PORT/tcp \
  -e "GCS_PORT=$GCS_PORT" \
  -e "PARAM_FILE=$PARAM_FILE" \
  -e "SIM_OPTIONS=-m --target-system=$SYS_ID $SIM_OPTIONS" \
  --entrypoint "/external/entryPoint.sh" \
  flytrex/flyhawk-sitl-docker:latest $SYS_ID
exit $?
