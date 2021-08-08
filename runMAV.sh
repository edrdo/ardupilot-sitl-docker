#! /bin/bash

# what modified
#   Remove --rm option at 17 row to keep running container buckground
#   add PATH where current direction.

if [ $# -ne 3 ] 
then
  echo "Usage: runMAV.sh <system_id> <gcs_host> <gcs_port>"
  exit 1
fi

SYS_ID=$1
GCS_HOST=$2
GCS_PORT=$3
#SCRIPTS_DIR=$(cd $(dirname $(which $0)); pwd)
SCRIPTS_DIR=$(dirname $(which $0); pwd)

echo "Running SITL simulation ..."
echo SYS_ID=$SYS_ID GCS_HOST=$2 GCS_PORT=$3
echo SIM_OPTIONS=$SIM_OPTIONS
docker run -itd \
  -v $SCRIPTS_DIR:/external \
  -e "SIM_OPTIONS=--out=udpout:$GCS_HOST:$GCS_PORT --out=udpout:$GCS_HOST:14550 -m --target-system=$SYS_ID $SIM_OPTIONS" \
  -p 5760:5760 -p 5501:5501/udp \
  --entrypoint "/external/entryPoint.sh" \
  temmiehoihoi/sitl_image:latest $SYS_ID
exit $?
#  -p $GCS_PORT:$GCS_PORT/udp -p 14550:14550/udp -p 5501:5501/tcp \
