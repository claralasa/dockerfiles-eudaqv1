# EUDAQ dockerfile

Creates the environment to run the EUDAQ framework. 
This image is based on an ubuntu-16.04 and contains
the necessary packages to run (or develop) the EUDAQ
framework in a real test-beam setup

## Installation
Assuming ```docker``` and ```docker-compose``` is 
installed on your system (host-computer).

1. Clone the docker eudaq repository and configure it
```bash 
$ git clone https://github.com/duartej/dockerfiles.git 
$ cd dockerfiles/eudaq
$ source setup.sh
```
The ```setup.sh``` script will create some ```Dockerfile```
and some ```docker-compose*.yml``` files. It also creates
the directories ```$HOME/eudaq_data/logs``` and 
```$HOME/eudaq_data/data```, where logs and raw data will
be sent in the host computer.

Note that a eudaq repository will be clone at 
```$HOME/repos/eudaq``` (unless it is already in that location).
This repository will be linked to the containers in ```development```
mode.

2. Download the automated build from the dockerhub: 
```bash
$ docker pull duartej/eudaqv1-ubuntu
```
or alternativelly you can build an image from the
[Dockerfile](Dockerfile)
```bash
# Using docker
$ docker build -t="duartej/eudaqv1-ubuntu" github.com/duartej/eudaq
# Using docker-compose
$ docker-compose build eudaqv1-ubuntu
```
## Usage: production environment
The production environment uses the 
[EUDAQ v1.7-dev](https://github.com/eudaq/eudaq/tree/v1.7-dev)
branch. 

The **recommended way** to launch all needed services is
with _docker-compose_
```bash 
docker-compose -f docker-compose.yml -f production.yml up 
```
One service per each element of the framework (run control, 
logger, data collector, online monitor, TLU producer, ... \<to
be defined which are the minimum needed\>) is created, 
all connected to the run control at ```tcp://172.20.168.2```

To run only one particular service:
```bash
docker-compose -f docker-compose.yml -f production.yml run --rm <service_name>
```
note, however, that run control and the logger are always launched as
needed for any of the EUDAQ producers or components.

If you want to add other element of the framework, just create
a container using the ```duartej/eudaqv1-ubuntu``` image.Be sure you 
connect the service to the ```<foldername>_static_network``` (check your 
available networks ```docker network ls```; and assign an unused ip:
```bash
$ docker run --rm -i \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=unix${DISPLAY} \
    --network <foldername>_static_network \
    --ip 172.20.168.XX \
    duartej/eudaqv1-ubuntu
# Once inside the container, lauch the process you are 
# interested, and remember to connect (if needed) to run control
# at tcp://172.20.168.2
```

**DISCLAIMER: in alpha yet, not tested in production environments**

## Usage: development environment
The development environment uses the EUDAQ repository placed in
the host computer at ```$HOME/repos/eudaq```, which was previously
cloned and checkout to v1.7-dev branch in the installation step.

Analogously to the production environment, the **recommended way** to
launch all needed services is with _docker-compose_, this time without
explicitely especify the yaml files (as uses the default and the override
mechanism).
```bash 
$ docker-compose up 
```
An extra service is available in order to allow compilation of the
developed code: ```devcode``` . The build directory in the container 
is found in the ```/eudaq/eudaq/build```:
```bash
$ docker-compose run --rm devcode
```

