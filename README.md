# ArduPilot SITL Docker image 

_Eduardo R. B. Marques_ [[edrdo](https://github.com/edrdo)]

## Description

This repository contains a Dockerfile for running [ArduPilot in SITL mode](https://ardupilot.org/dev/docs/sitl-simulator-software-in-the-loop.html) and 
related helper scripts and files. 

The image can be obtained from DockerHub [here](https://hub.docker.com/r/edrdo/ardupilot-sitl-docker). 

## Helper scripts 

### `runMAV.sh`

Usage:

    runMAV.sh <System id> <GCS host> <GCS port>

This will start the Ardupilot SITL container letting you customize the Ardupilot system id (aka `SYSID_THISMAV`) parameter, thus allowing you to have multiple containers / simulated MAVs properly (i.e., with different system ids), along with the GCS host and port.

In principle, you should be able to use the same GCS host/port pair for multiple containers/simulated MAVs, e.g., GCS software like [QGroundControl](http://qgroundcontrol.com/)  uses a single UDP port for communication with multiple MAVs.

### `runMAV-macos.sh`

This script is MacOS specific and should be used when the GCS is running on your local MacOS machine.

Calling 

    runMAV-macos.sh <System id> <GCS port>` 
    
is shorthand for 
    
    runMAV.sh <System id> docker.for.mac.localhost <GCS port>


### `entryPoint.sh`

The script runs as the entry point for the container at startup (overriding the container's default one), in support of the system id setting by `runMAV.sh`. Thus it is not meant to be called directly, though you may wish to edit it for further customisation.

### `cshell.sh`

This script starts the container with a bash shell. 
It may be useful for debugging.

### `build.sh` and `push.sh`

These are scripts for building the container and pushing it onto Docker Hub.

## Helper files

### `extra-locations.txt`

Add custom locations here. Entries in this file will be added to 
`/ardupilot/Tools/autotest/locations.txt`. 

### `start-location.conf` 

Define the start location for the simulation here.

