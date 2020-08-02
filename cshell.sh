echo "Docker container will now start ..."
docker run \
  --rm -h ardupilot-sitl -it \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -u ardupilot flytrex/flyhawk-sitl-docker:latest /bin/bash
