#!/bin/bash

# Wait some time to allow the runControl to wake up

echo "Initializing SERVICE: $1"
if [ "X$1" == "XrunControl" ];
then
    CMD="euRun.exe -a tcp://44000"
elif [ "X$1" == "Xlogger" ];
then
    sleep 3;
    CMD="euLog.exe -r tcp://172.20.128.2:44000"
elif [ "X$1" == "XdataCollector" ];
then
    sleep 6;
    # Change the uid for the data 
    CMD="TestDataCollector.exe -r tcp://172.20.128.2:44000"
elif [ "X$1" == "XonlineMon" ];
then
    sleep 10;
    CMD="OnlineMon.exe -tc 0 -r tcp://172.20.128.2:44000";
elif [ "X$1" == "XTestProducer" ];
then
    sleep 20;
    CMD="TestProducer.exe -r tcp://172.20.128.2:44000";
elif [ "X$1" == "XNIProducer" ];
then
    sleep 20;
    CMD="echo 'NOT IMPLEMENTED YET: NIProducer.exe -r tcp://172.20.128.2:44000'";
elif [ "X$1" == "XTLU" ];
then
    sleep 20;
    CMD="TLUProducer.exe -r tcp://172.20.128.2:44000";
fi

exec ${CMD}
