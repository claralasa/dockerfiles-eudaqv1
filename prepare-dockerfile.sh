#!/bin/bash
# 
# Any time a new computer from the hut is connected, the
# credentials of this computer should be added to the X-server
# authority  (xauth), and the display to send the x-windows 
# must be updated
# 
# jorge.duarte.campderros@cern.ch (CERN/IFCA)
#

# Check the xaut file exist and create it if not
XAUTH=/tmp/.docker.xauth
if [ ! -e "$XAUTH" ];
then
    sudo touch $XAUTH;
fi
## Update xauth and change to proper permissions
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | sudo xauth -f $XAUTH nmerge -
sudo chmod 777 $XAUTHa

## Put the proper address and  display
POSTDISPLAY=`echo $DISPLAY | sed 's/^[^:]*\(.*\)/172.17.0.1\1/'`

# Create the services and 
INFILE=.temp-aida-h6b.yaml
FIFILE=aida-h6b.yaml
cp $INFILE $FIFILE
sed -i "s#@DOCKERNET#${POSTDISPLAY}#g" $FIFILE
echo "COMPUTER ALLOWED TO USE X-SERVER: ${DISPLAY}"
echo "Dockerfiles ready to be used: $FIFILE"
echo "-----------------------------------------"
echo "All available services can be run as:"
echo "docker-compose -f aida-h6b.yaml up -d"
