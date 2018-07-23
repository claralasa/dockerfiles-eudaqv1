# 
# eudaq Dockerfile
# https://github.com/duartej/dockerfiles/eudaq
#
# Creates the environment to run the EUDAQ 
# framework 
#

FROM ubuntu:16.04
LABEL author="jorge.duarte.campderros@cern.ch" \ 
    version="1.0-e00b0c9655" \ 
    description="Docker image for EUDAQ framework (duartej/eudaq commit)"

# Place at the directory
WORKDIR /eudaq

# Install all dependencies
RUN apt-get update && apt-get -y install \ 
  openssh-server \ 
  qt5-default \ 
  git \ 
  cmake \ 
  libusb-dev \ 
  libusb-1.0 \ 
  pkgconf \ 
  python \ 
  python-dev \ 
  python-numpy \ 
  vim \ 
  g++ \
  gcc \
  gfortran \
  binutils \
  libxpm4 \ 
  libxft2 \ 
  libtiff5 \ 
  libtbb-dev \ 
  sudo \ 
  && rm -rf /var/lib/apt/lists/*

# ROOT 
RUN mkdir /rootfr \ 
  && wget https://root.cern.ch/download/root_v6.14.00.Linux-ubuntu16-x86_64-gcc5.4.tar.gz -O /rootfr/root.v6.14.00.tar.gz \ 
  && tar -xf /rootfr/root.v6.14.00.tar.gz -C /rootfr \ 
  && rm -rf /rootfr/root.v6.14.00.tar.gz

ENV ROOTSYS /rootfr/root
# BE aware of the ROOT libraries
ENV LD_LIBRARY_PATH /rootfr/root/lib
ENV PYTHONPATH /rootfr/root/lib

# download the code, checkout the release and compile
# This will be used only for production!
# For development case, the /eudaq/eudaq directory
# is "bind" from the host computer 
# -- XXX To be switch back to eudaq!
RUN git clone -b v1.x-dev --single-branch https://github.com/duartej/eudaq.git \ 
  && cd eudaq \ 
  && mkdir -p /eudaq/eudaq/extern/ZestSC1 \ 
  && mkdir -p /eudaq/eudaq/extern/tlufirmware

# COPY The needed files for the TLU and pxar (CMS phase one pixel)
COPY ZestSC1.tar.gz /eudaq/eudaq/extern/ZestSC1.tar.gz
COPY tlufirmware.tar.gz /eudaq/eudaq/extern/tlufirmware.tar.gz
COPY libftd2xx-x86_64-1.4.6.tgz /eudaq/eudaq/extern/libftd2xx-x86_64-1.4.6.tgz

# Untar files and continue with the compilation
RUN cd /eudaq/eudaq \ 
  && tar xzf extern/ZestSC1.tar.gz -C extern && rm extern/ZestSC1.tar.gz \
  && tar xzf extern/tlufirmware.tar.gz -C extern && rm extern/tlufirmware.tar.gz \
  # The pxar library for CMS phase I pixel
  && tar xzf extern/libftd2xx-x86_64-1.4.6.tgz -C extern \
  && mv extern/release extern/libftd2xx-x86_64-1.4.6 && rm extern/libftd2xx-x86_64-1.4.6.tgz \ 
  && cp extern/libftd2xx-x86_64-1.4.6/build/libftd2xx.* /usr/local/lib/ \
  && chmod 0755 /usr/local/lib/libftd2xx.so.1.4.6 \
  && ln -sf /usr/local/lib/libftd2xx.so.1.4.6 /usr/local/lib/libftd2xx.so \
  && cp extern/libftd2xx-x86_64-1.4.6/*.h /usr/local/include/ \ 
  && git clone https://github.com/psi46/pixel-dtb-firmware extern/pixel-dtb-firmare \ 
  && git clone https://github.com/psi46/pxar.git extern/pxar && cd extern/pxar && git checkout production \ 
  && mkdir -p build && cd build && cmake .. && make -j4 install && cd /eudaq/eudaq \ 
  # End pxar library 
  && mkdir -p build \ 
  && cd build \ 
  && cmake .. -DBUILD_tlu=ON -DBUILD_python=ON -DBUILD_ni=ON \ 
  && make -j4 install
# STOP ONLY FOR PRODUCTION

ENV PXARPATH="/eudaq/eudaq/extern/pxar"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PXARPATH}/lib:/eudaq/eudaq/lib"
ENV PYTHONPATH="${PYTHONPATH}:/eudaq/eudaq/lib:/eudaq/eudaq/python"
ENV PATH="${PATH}:/rootfr/root/bin:/eudaq/eudaq/bin"

COPY initialize_service.sh /usr/bin/initialize_service.sh

# Create a couple of directories needed
RUN mkdir -p /logs && mkdir -p /data
# Add eudaquser, allow to call sudo without password
RUN useradd -md /home/eudaquser -ms /bin/bash -G sudo eudaquser \ 
  && echo "eudaquser:docker" | chpasswd \
  && echo "eudaquser ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers 
# Give previously created folders ownership to the user
RUN chown -R eudaquser:eudaquser /logs && chown -R eudaquser:eudaquser /data \
  && chown -R eudaquser:eudaquser /eudaq
USER eudaquser

