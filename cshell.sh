echo "Docker container will now start ..."
docker run \
  --rm -h ardupilot-sitl -it \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -u ardupilot edrdo/ardupilot-sitl-docker:latest /bin/bash
