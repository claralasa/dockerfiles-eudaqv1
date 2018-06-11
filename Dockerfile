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
  libeigen3-dev \ 
  default-jdk \ 
  libgsl-dev \ 
  libxpm-dev \ 
  libxft-dev \ 
  libx11-dev \ 
  libxext-dev \
  subversion \ 
  sudo \ 
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
# XXX -- PROV. until merge from duartej -> eudaq
#RUN git clone https://github.com/eudaq/eudaq.git \ 
#  && cd eudaq \ 
#  && git checkout tags/v1.7.0 -b v1.7.0 \ 
RUN git clone https://github.com/duartej/eudaq.git \ 
  && cd eudaq \ 
  && git checkout v1.7-dev \ 
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
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/eudaq/eudaq/lib"
ENV PYTHONPATH="${PYTHONPATH}:/eudaq/eudaq/lib:/eudaq/eudaq/python"
ENV PATH="${PATH}:/rootfr/root/bin:/eudaq/eudaq/bin"

COPY initialize_service.sh /usr/bin/initialize_service.sh

# ILCSOFT (for EUTelescope) and LCIO ===================
ENV ILCSOFT /eudaq/ilcsoft
ENV EUTELESCOPE ${ILCSOFT}/v01-19-02/Eutelescope/master/
ENV EUDAQ /eudaq/eudaq
ENV ILCSOFT_CMAKE_ENV ${ILCSOFT}/v01-19-02/ILCSoft.cmake.env.sh
ENV MILLEPEDEII ${ILCSOFT}/v01-19-02/Eutelescope/master/external/millepede2/tags/V04-03-09
ENV MILLEPEDEII_VERSION tags/V04-03-09
ENV GEAR ${ILCOSFT}/v01-19-02/gear/v01-06-eutel-pre
ENV MARLIN ${ILCSOFT}/v01-19-02/Marlin/v01-11
ENV MARLIN_DLL ${EUTELESCOPE}/lib/libEutelescope.so:${EUTELESCOPE}/lib/libEutelProcessors.so:${EUTELESCOPE}/lib/libEutelReaders.so:${EUDAQ}/lib/libNativeReader.so:${MARLIN_DLL}
ENV GBL ${ILCSOFT}/v01-19-02/GBL/V02-01-03
ENV PATH="${PATH}:${MARLIN}/bin:${MILLEPEDEII}:${EUTELESCOPE}/bin:${GEAR}/tools:${GEAR}/bin"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${EUTELESCOPE}/lib:${GEAR}/lib:${GBL}/lib"

COPY release-standalone-tuned.cfg ${ILCSOFT}/release-standalone-tuned.cfg
#  XXX -- PROVISIONAL UNTIL EUTelescope includes new kRD53A
COPY eutelescope.py ${ILCSOFT}/eutelescope_patched.py
#  XXX -- END PROVISIONAL UNTIL EUTelescope includes new kRD53A

# ILCSOFT compilation
RUN mkdir -p ${ILCSOFT} \
  && git clone -b dev-base https://github.com/eutelescope/ilcinstall $ILCSOFT/ilcinstall \
  && cd ${ILCSOFT}/ilcinstall \
  #  XXX -- PROVISIONAL UNTIL EUTelescope includes new kRD53A
  && cp ${ILCSOFT}/eutelescope_patched.py ${ILCSOFT}/ilcinstall/ilcsoft/eutelescope.py \
  #  XXX -- END PROVISIONAL UNTIL EUTelescope includes new kRD53A
  && ${ILCSOFT}/ilcinstall/ilcsoft-install -i -v ${ILCSOFT}/release-standalone-tuned.cfg 
# ILCSOFT (for EUTelescope) and LCIO: DONE ===================

# Recompile eudaq with lcio and eutelescope
RUN . ${ILCSOFT}/v01-19-02/Eutelescope/master/build_env.sh \
  && cd /eudaq/eudaq/build \ 
  && cmake .. -DBUILD_tlu=ON -DBUILD_python=ON -DBUILD_ni=ON -DUSE_LCIO=ON -DBUILD_nreader=ON -DBUILD_cmspixel=ON \ 
  && make -j4 install

# Create a couple of directories needed
RUN mkdir -p /logs && mkdir -p /data
# Add eudaquser, allow to call sudo without password
RUN useradd -md /home/eudaquser -ms /bin/bash -G sudo eudaquser \ 
  && echo "eudaquser:docker" | chpasswd \
  && echo "eudaquser ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers 
# Give previously created folders ownership to the user
RUN chown -R eudaquser:eudaquser /logs && chown -R eudaquser:eudaquser /data \
  && chown -R eudaquser:eudaquser /eudaq
  #&& chown -R eudaquser:eudaquser ${ILCSOFT} && chown -R eudaquser:eudaquser /eudaq/eudaq
USER eudaquser

ENTRYPOINT . ${ILCSOFT}/v01-19-02/Eutelescope/master/build_env.sh && /bin/bash -i
