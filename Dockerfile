# 
# eudaq Dockerfile
# https://github.com/duartej/dockerfiles/eudaq
#
# Creates the environment to run the EUDAQ 
# framework 
#

FROM ubuntu:16.04
LABEL author="jorge.duarte.campderros@cern.ch" \ 
    version="0.1-alpha" \ 
    description="Docker image for EUDAQ framework"

# Place at the directory
WORKDIR /eudaq

# Install all dependencies
RUN apt-get update && apt-get -y install \ 
  openssh-server \ 
  qt5-default \ 
  git \ 
  cmake \ 
  libusb-dev \ 
  pkgconf \ 
  python \ 
  python3 \ 
  python-dev \ 
  python3-dev \
  python-numpy \ 
  vim \ 
  g++ \
  gcc \
  gfortran \
  binutils \
  libxpm4 \ 
  libxft2 \ 
  libtiff5 \ 
  && rm -rf /var/lib/apt/lists/*

# ROOT 
RUN mkdir /rootfr \ 
  && wget https://root.cern.ch/download/root_v6.10.02.Linux-ubuntu16-x86_64-gcc5.4.tar.gz -O /rootfr/root.v6.10.02.tar.gz \ 
  && tar -xf /rootfr/root.v6.10.02.tar.gz -C /rootfr \ 
  && rm -rf /rootfr/root.v6.10.02.tar.gz

ENV ROOTSYS /rootfr/root
# BE aware of the ROOT libraries
ENV LD_LIBRARY_PATH /rootfr/root/lib
ENV PYTHONPATH /rootfr/root/lib

# download the code, checkout the release and compile
# This will be used only for production!
# For development case, the /eudaq/eudaq directory
# is "bind" from the host computer 
RUN git clone https://github.com/eudaq/eudaq.git \ 
  && cd eudaq \ 
  && git checkout tags/v1.7.0 -b v1.7.0 \ 
  && mkdir -p /eudaq/eudaq/extern/ZestSC1 \ 
  && mkdir -p /eudaq/eudaq/extern/tlufirmware

# COPY The needed files for the TLU
COPY ZestSC1.tar.gz /eudaq/eudaq/extern/ZestSC1.tar.gz
COPY tlufirmware.tar.gz /eudaq/eudaq/extern/tlufirmware.tar.gz

# Untar files and continue with the compilation
RUN cd /eudaq/eudaq \ 
  && tar xzf extern/ZestSC1.tar.gz -C extern && rm extern/ZestSC1.tar.gz \
  && tar xzf extern/tlufirmware.tar.gz -C extern && rm extern/tlufirmware.tar.gz \
  && mkdir -p build \ 
  && cd build \ 
  && cmake .. -DBUILD_tlu=ON -DBUILD_python=ON -DBUILD_ni=ON \ 
  && make -j4 install
# STOP ONLY FOR PRODUCTION

ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/eudaq/eudaq/lib"
ENV PYTHONPATH="${PYTHONPATH}:/eudaq/eudaq/lib:/eudaq/eudaq/python"
ENV PATH="${PATH}:/rootfr/root/bin:/eudaq/eudaq/bin"

COPY initialize_service.sh /usr/bin/initialize_service.sh

# Create a couple of directories needed
RUN mkdir -p /logs && mkdir -p /data
RUN useradd -md /home/eudaquser -ms /bin/bash eudaquser
RUN chown -R eudaquser:eudaquser /logs && chown -R eudaquser:eudaquser /data 
USER eudaquser

