#!/usr/bin/env bash

set -x

ANDROID_IMAGE_ID="ami-02d7c6eff157797a0"

export SITL_PORT=5${VEHICLE_ID}  # we assume ${VEHICLE_ID} is exactly 4 digits between 1000-1100

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

if ! ecs-cli compose --project-name "sitl-${SITL_PORT}" service list --cluster-config "staging-beehive" --cluster "staging-beehive" --region ${AWS_DEFAULT_REGION}
then
  echo "Failed to get esc service"
  exit 1
fi

aws ec2 terminate-instances --instance-ids "${ANDROID_INSTANCE_ID}"

ecs-cli compose --project-name "sitl-${SITL_PORT}" service rm
