#!/usr/bin/env bash

set -x
set -e

aws --version
ecs-cli --version

export SITL_PORT=5761  # TODO: find a way to get a dynamically aviliable port'
export SCRIPTS_DIR="$(cd $(dirname $(which $0)); pwd)/../sitl"
export SIM_OPTIONS=

if [ -f "${SCRIPTS_DIR}/flyhawk.parm" ]
then
  export SITL_PARAMS=$(<${SCRIPTS_DIR}/flyhawk.parm)
fi

export START_LOCATION=--custom-location=$(awk -F "=" "/${CUSTOM_LOCATION}"'/{print $2}' ${SCRIPTS_DIR}/extra-locations.txt)

export ENTRYPOINT='bash -c "echo \\"$${SITL_PARAMS}\\" > extra.parm; sim_vehicle.py -N -v ArduCopter --frame=hexa '"${START_LOCATION}"' --add-param-file=extra.parm -w --model hexa --no-mavproxy --sitl-instance-args=\\"-S --base-port '"${SITL_PORT} ${SIM_OPTIONS}"'\\" "'

echo "Preparing docker compose"
awk -v r="${SITL_PARAMS}" '{gsub(/\${SITL_PARAMS}/,r)}1' docker_compose_template.yml > docker-compose_stage1.yml
sed -e "s/\${VERSION}/${VERSION}/g; s/\${SITL_PORT}/${SITL_PORT}/g; s+\${ENTRYPOINT}+${ENTRYPOINT}+g; s/\${SIM_OPTIONS}/${SIM_OPTIONS}/g" docker-compose_stage1.yml > docker-compose.yml
rm docker-compose_stage1.yml

echo "Preparing ecs params"
sed -e "s/\${SITL_PORT}/${SITL_PORT}/g" ecs_params_template.yml > ecs-params.yml

ecs-cli compose --project-name "sitl-${SITL_PORT}" \
    service up \
    --private-dns-namespace "beehive_staging" \
    --vpc "vpc-0af4a153bf51abf0b" \
    --enable-service-discovery \
    --create-log-groups \
    --cluster-config "staging-beehive" \
    --cluster "staging-beehive" \
    --region "us-east-2" \
    --deployment-min-healthy-percent 0 \
    --timeout 5

if [ "$?" = "1" ]; then
  echo "Deploy failed"
  exit 1
fi
popd || exit
