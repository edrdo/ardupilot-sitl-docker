SCRIPTS_DIR=$(cd $(dirname $(which $0)); pwd)

echo "Docker container will now start ..."
docker run \
  --rm -h ardupilot-sitl -it \
  -v $SCRIPTS_DIR:/external \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -u ardupilot flytrex/flyhawk-sitl-docker:latest /bin/bash
