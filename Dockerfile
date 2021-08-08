FROM ubuntu:20.04

WORKDIR /ardupilot

RUN useradd -U -d /ardupilot ardupilot && \
    usermod -G users ardupilot

RUN apt-get update && apt-get install --no-install-recommends -y \
    lsb-release \
    sudo \
    software-properties-common 
RUN apt-get install --no-install-recommends -y software-properties-common 
RUN sudo apt-get install -y git 
ENV USER=ardupilot
RUN cd / && git clone https://github.com/ArduPilot/ardupilot.git

RUN echo "ardupilot ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ardupilot
RUN chmod 0440 /etc/sudoers.d/ardupilot

RUN chown -R ardupilot:ardupilot /ardupilot

USER ardupilot
RUN sudo apt-get update
RUN sudo apt-get install -y python
RUN sudo apt-get install -y pip
RUN pip install future
RUN /bin/bash
