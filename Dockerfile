FROM ubuntu:16.04 as intermediate

WORKDIR /ardupilot

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y git
ARG SSH_PRIVATE_KEY
RUN mkdir ~/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
RUN chmod 600 ~/.ssh/id_rsa

RUN touch ~/.ssh/known_hosts
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts

ARG VERSION
RUN cd / && git clone git@github.com:Flytrex/flytrex_ardupilot.git ardupilot
RUN git checkout "${VERSION}"
RUN git config submodule.modules/uavcan.url git@github.com:Flytrex/uavcan.git
RUN git config submodule.modules/mavlink.url git@github.com:Flytrex/ardupilot_mavlink.git
RUN git submodule update --init --recursive

FROM ubuntu:16.04

WORKDIR /ardupilot

RUN useradd -U -d /ardupilot ardupilot && \
    usermod -G users ardupilot

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install --no-install-recommends -y \
    lsb-release \
    sudo \
    software-properties-common \
    python-software-properties

COPY --from=intermediate /ardupilot /ardupilot

RUN echo "ardupilot ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ardupilot
RUN chmod 0440 /etc/sudoers.d/ardupilot

RUN chown -R ardupilot:ardupilot /ardupilot

USER ardupilot
RUN USER=`whoami` /ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh -y
RUN sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sudo apt-get install -y cmake

WORKDIR /ardupilot
RUN git clone git://github.com/JSBSim-Team/jsbsim.git 

# temporary only
RUN sed -i '1i#include <cstdlib>' libraries/AP_Parachute/AP_Parachute.cpp

RUN cd jsbsim && mkdir build && cd build && \
cmake -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native -mtune=native" -DCMAKE_C_FLAGS_RELEASE="-O3 -march=native -mtune=native" -DCMAKE_BUILD_TYPE=Release .. && \
make -j2 

RUN make sitl-configure copter

ENV CCACHE_MAXSIZE=1G
ENV PATH /usr/lib/ccache:/ardupilot/Tools:${PATH}
ENV PATH /ardupilot/Tools/autotest:${PATH}
ENV PATH /ardupilot/.local/bin:${PATH}
ENV PATH /ardupilot/jsbsim/build/src:${PATH}

