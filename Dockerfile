FROM ubuntu:18.04

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
RUN sudo add-apt-repository universe
RUN sudo apt-get update
RUN sudo apt-get install -y python-pip
RUN sudo apt-get install -y python3-pip
RUN pip3 install --upgrade pip
RUN git submodule update --init --recursive
RUN python -m pip install future pexpect mavproxy empy
ENV PATH /ardupilot/jsbsim/build/src:/ardupilot/.local/bin:/ardupilot/Tools/autotest:/usr/lib/ccache:/ardupilot/Tools:/ardupilot/jsbsim/build/src:/ardupilot/.local/bin:/ardupilot/Tools/autotest:/usr/lib/ccache:/ardupilot/Tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN /bin/bash
