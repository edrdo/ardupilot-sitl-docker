#!/usr/bin/env bash

set -x

ANDROID_IMAGE_ID="ami-02d7c6eff157797a0"

export SITL_PORT=5${VEHICLE_ID}  # we assume ${VEHICLE_ID} is exactly 4 digits between 1000-1100

echo "Preparing docker compose"
awk -v r="${SITL_PARAMS}" '{gsub(/\${SITL_PARAMS}/,r)}1' docker_compose_template.yml > docker-compose_stage1.yml
sed -e "s/\${VERSION}/${VERSION}/g; s/\${SITL_PORT}/${SITL_PORT}/g; s+\${ENTRYPOINT}+${ENTRYPOINT}+g; s/\${SIM_OPTIONS}/${SIM_OPTIONS}/g" docker-compose_stage1.yml > docker-compose.yml
rm docker-compose_stage1.yml

echo "Preparing ecs params"
sed -e "s/\${SITL_PORT}/${SITL_PORT}/g" ecs_params_template.yml > ecs-params.yml

ANDROID_INSTANCE_ID=$(aws ec2 describe-instances \
                        --filters "Name=instance-state-name,Values=running" \
                                  "Name=tag:Name,Values=sitl-${SITL_PORT}" \
                        --query 'Reservations[*].Instances[*].InstanceId' --output text
)

if [ -z ${ANDROID_INSTANCE_ID} ]
then
  echo "Failed to get Android instance id"
  exit 1
fi

SERVICE_STATUS=$(aws ecs describe-services --cluster "staging-beehive" --services "sitl-${SITL_PORT}" --query 'services[*].status' --output text)
if [ "${SERVICE_STATUS}" != "ACTIVE" ]
then
  echo "Failed to get esc service"
  exit 1
fi

aws ec2 terminate-instances --instance-ids "${ANDROID_INSTANCE_ID}"

aws ecs update-service --cluster "staging-beehive" --service "sitl-${SITL_PORT}" --desired-count 0
aws ecs delete-service --cluster "staging-beehive" --service "sitl-${SITL_PORT}"
