#!/usr/bin/env bash

set -x
set -e

ANDROID_IMAGE_ID="ami-02d7c6eff157797a0"

export SITL_PORT=5${VEHICLE_ID}  # we assume ${VEHICLE_ID} is exactly 4 digits between 1000-1100
export SCRIPTS_DIR="$(cd $(dirname $(which $0)); pwd)/../sitl"
export SIM_OPTIONS=

if [ -f "${SCRIPTS_DIR}/flyhawk.parm" ]
then
  export SITL_PARAMS=$(<${SCRIPTS_DIR}/flyhawk.parm)
fi

export START_LOCATION=--custom-location=$(awk -F "=" "/${CUSTOM_LOCATION}"'/{print $2}' ${SCRIPTS_DIR}/extra-locations.txt)
export ENTRYPOINT='bash -c "echo \\"$${SITL_PARAMS}\\" > extra.parm; sim_vehicle.py -N -v ArduCopter --frame=hexa '"${START_LOCATION}"' --add-param-file=extra.parm -w --model hexa --no-mavproxy --sitl-instance-args=\\"-S --base-port '"${SITL_PORT} ${SIM_OPTIONS}"'\\" "'

ANDROID_INSTANCE_ID=''

function cleanup_after_error {
  RETVAL=$?

  set +e

  if [ -n "${ANDROID_INSTANC_ID}" ]
  then
    aws ec2 terminate-instances --instance-ids "${ANDROID_INSTANC_ID}"
  fi

  if ecs-cli compose --project-name "sitl-${SITL_PORT}" service list --cluster-config "staging-beehive" --cluster "staging-beehive" --region ${AWS_DEFAULT_REGION}
  then
    ecs-cli compose --project-name "sitl-${SITL_PORT}" service rm
  fi

  exit ${RETVAL}
}
trap cleanup_after_error ERR

echo "Launching Android instance"
ANDROID_INSTANCE_ID=$(aws ec2 run-instances \
                        --image-id ${ANDROID_IMAGE_ID} \
                        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=sitl-$\{SITL_PORT\}}]' \
                        --count 1 \
                        --instance-type t3.medium \
                        --key-name SITL \
                        --security-group-ids sg-09bcd16c1aedccf81 \
                        --subnet-id subnet-07be964d \
                        --associate-public-ip-address \
                        --query 'Instances[*].InstanceId' --output text 
)
if [ -z ${ANDROID_INSTANCE_ID} ]
then
  echo "Failed to get Android instance id"
  exit 1
fi

echo "Preparing docker compose"
awk -v r="${SITL_PARAMS}" '{gsub(/\${SITL_PARAMS}/,r)}1' docker_compose_template.yml > docker-compose_stage1.yml
sed -e "s/\${VERSION}/${VERSION}/g; s/\${SITL_PORT}/${SITL_PORT}/g; s+\${ENTRYPOINT}+${ENTRYPOINT}+g; s/\${SIM_OPTIONS}/${SIM_OPTIONS}/g" docker-compose_stage1.yml > docker-compose.yml
rm docker-compose_stage1.yml

echo "Preparing ecs params"
sed -e "s/\${SITL_PORT}/${SITL_PORT}/g" ecs_params_template.yml > ecs-params.yml

echo "Launching SITL service"
ecs-cli compose --project-name "sitl-${SITL_PORT}" \
    service up \
    --private-dns-namespace "beehive_staging" \
    --vpc "vpc-5c17fc35" \
    --enable-service-discovery \
    --create-log-groups \
    --cluster-config "staging-beehive" \
    --cluster "staging-beehive" \
    --region ${AWS_DEFAULT_REGION} \
    --deployment-min-healthy-percent 0 \
    --timeout 5

if [ "$?" = "1" ]; then
  echo "Can't launch SITL"
  exit 1
fi

echo "Getting Android public ip"
for i in {1..10}
do
  ANDROID_PUBLIC_IP=$(aws ec2 describe-instances \
                        --instance-ids ${ANDROID_INSTANCE_ID} \
                        --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
  )
  if [ ! -z ${ANDROID_PUBLIC_IP} ]
  then
    break
  fi
  sleep 1
done
if [ -z ${ANDROID_PUBLIC_IP} ]
then
  echo "Can't get Android public ip"
  exit 1
fi

aws s3 cp s3://mc-apks.beehive.flytrex.com/${MC_VERSION}.apk ${MC_VERSION}.apk
scp -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} ${MC_VERSION}.apk genymotion@${ANDROID_PUBLIC_IP}:/data/local/tmp/mc.apk
scp -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} launch_mc.sh genymotion@${ANDROID_PUBLIC_IP}:/data/local/tmp/launch_mc.sh
ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} genymotion@${ANDROID_PUBLIC_IP} \
  "su -c \"VEHICLE_ID=${VEHICLE_ID} SRV_RECORD=sitl-${SITL_PORT}.beehive_staging sh /data/local/tmp/launch_mc.sh\""

echo "https://genymotion:${ANDROID_INSTANCE_ID}@${ANDROID_PUBLIC_IP}"
