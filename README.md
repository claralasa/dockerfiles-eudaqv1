# EUDAQ dockerfile

Creates the environment to run the EUDAQ framework. This image is based on an 
[phusion/baseimage](https://hub.docker.com/r/phusion/baseimage) built over a 
ubuntu-18.04, and contains the necessary packages to run (or develop) the EUDAQ
framework in a real test-beam setup. In order to use LCIO and EUTelescope with
this image, take a look at [dockerfiles-eutelescope](https://github.com/duartej/dockerfiles-eutelescope)
package.

## Installation
Assuming ```git```, ```docker``` and ```docker-compose``` is installed on your 
system (host-computer). 

1. Clone the docker eudaq repository and configure it
```bash 
$ git clone https://github.com/duartej/dockerfiles-eudaqv1
$ cd dockerfiles-eudaqv1
$ source setup.sh
```
The ```setup.sh``` script will create some ```docker-compose*.yml``` files. It 
also creates the directories ```$HOME/eudaq_data/logs``` and 
```$HOME/eudaq_data/data```, where logs and raw data will be sent in the host 
computer.

Note that a eudaq repository will be cloned at ```$HOME/repos/eudaq``` (unless 
it is already in that location). This repository will be linked to the 
containers in ```development``` mode.

2. Download the automated build from the dockerhub: 
```bash
$ docker pull duartej/eudaqv1:latest
```
or alternativelly you can build an image from the [Dockerfile](Dockerfile)
```bash
# Using docker
$ docker build github.com/duartej/eudaqv1:latest
# Using docker-compose within the repo directory
$ docker-compose build eudaqv1
```
## Usage: production environment
The production environment uses the [EUDAQ v1.x-dev](https://github.com/eudaq/eudaq/tree/v1.x-dev) branch. 

The **recommended way** to launch all needed services is with _docker-compose_ 
You should be at the _dockerfiles-eudaqv1_ repository folder and launch:
```bash 
$ docker-compose -f docker-compose.yml -f production.yml up 
```
One service per each element of the framework (run control, logger, data 
collector, online monitor, TLU producer, ... \<to be defined which are the 
minimum needed\>) is created, all connected to the run control at 
```tcp://172.20.168.2```

To run only one particular service:
```bash
$ docker-compose -f docker-compose.yml -f production.yml run --rm <service_name>
```
note, however, that run control and the logger are always launched as
needed for any of the EUDAQ producers or components. ```service_name``` 
could be: 
 * ```runControl```
 * ```logger```
 * ```dataCollector```
 * ```onlineMon```
 * ```TestProducer```
 * ```NIProducer```
 * ```TLU```

If you want to add other element of the framework, just create a container using 
the ```duartej/eudaqv1``` image. Be sure you connect the service to the 
```<foldername>_static_network``` (check your available networks ```docker network
ls```); and assign an unused ip:
```bash
$ docker run --rm -i \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=unix${DISPLAY} \
    --network <foldername>_static_network \
    --ip 172.20.168.XX \
    duartej/eudaqv1
# Once inside the container, lauch the process you are 
# interested, and remember to connect (if needed) to run control
# at tcp://172.20.168.2
```

**DISCLAIMER: in alpha yet, not tested in production environments**

## Usage: development environment
The development environment uses the EUDAQ repository placed in the host computer 
at ```$HOME/repos/eudaq```, which was previously cloned and checkout to v1.x-dev 
branch in the installation step.

Analogously to the production environment, the **recommended way** to launch all
needed services is with _docker-compose_, this time without explicitely especify 
the yaml files (as uses the default and the override mechanism).
```bash 
$ docker-compose up 
```
or launching a concrete service as explained in the production section:
```bash
$ docker-compose run --rm <service_name>
```

An extra service is available in order to allow compilation of the developed code: 
```devcode``` and ```devcode-p``` (the privileged version, to be run for TLU related
check).  The build directory in the container  is found in the ```/eudaq/eudaq/build```: 
```bash
$ docker-compose run --rm devcode
```


