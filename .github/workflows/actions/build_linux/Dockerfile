FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update
RUN apt install -y build-essential curl wget software-properties-common
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - > /usr/share/keyrings/kitware-archive-keyring.gpg 
RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main'  >> /etc/apt/sources.list
# TODO: get rid of PPA
RUN add-apt-repository ppa:savoury1/gcc-defaults-9
RUN apt update
RUN apt install -y cmake g++-9 libxcb1-dev libgtk-3-dev libxcb-*-dev libxkbcommon-dev libxkbcommon-x11-dev
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9 