#! /bin/bash

if [ $# -lt 3 ] || [ $# -gt 5 ] 
then
  echo "Usage: runMAV.sh <system_id> <gcs_host> <gcs_port> [<Flyhawk_Vx.x] [<optional_param_file>]"
  exit 1
fi

SYS_ID=$1
GCS_HOST=$2
GCS_PORT=$3
VERSION="Flyhawk"
if [ $# -ge 4 ]
then
  VERSION="$4"
fi
if [ $# -eq 5 ]
then
  PARAM_FILES="--add-param-file=/external/$5"
fi
SCRIPTS_DIR=$(cd $(dirname $(which $0)); pwd)

if [ -f "flyhawk.parm" ]
then
  PARAM_FILES+=" --add-param-file=/external/flyhawk.parm"
fi

echo "Running SITL simulation ..."
echo SYS_ID=$SYS_ID GCS_HOST=$2 GCS_PORT=$3
echo SIM_OPTIONS=$SIM_OPTIONS
docker run --rm -it \
  -v $SCRIPTS_DIR:/external \
  -p $GCS_HOST:$GCS_PORT:$GCS_PORT/tcp \
  -e "GCS_PORT=$GCS_PORT" \
  -e "PARAM_FILES=$PARAM_FILES" \
  -e "SIM_OPTIONS=-m --target-system=$SYS_ID $SIM_OPTIONS" \
  --entrypoint "/external/entryPoint.sh" \
  beehive/sitl:${VERSION} $SYS_ID
exit $?
