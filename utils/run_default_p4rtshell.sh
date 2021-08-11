#!/bin/bash

DEFAULT_PROG=l2switch
P4RTDIR="/home/pi/p4pi/t4p4s/t4p4s/examples/p4rt_files"

echo "Generating P4Runtime files..."

if [ ! -d "$P4RTDIR" ]
then
	echo "Creating the directory for P4Runtime files: $P4RTDIR"
	mkdir $P4RTDIR
fi

pushd ${P4RTDIR}
p4c-bm2-ss --p4runtime-files ${DEFAULT_PROG}.p4runtime.txt --toJSON ${DEFAULT_PROG}.json /home/pi/p4pi/t4p4s/t4p4s/examples/${DEFAULT_PROG}.p4
popd

echo "Launching P4Runtime-shell..."
python3.9 -m p4runtime_sh --grpc-addr localhost:50051 --device-id 1 --election-id 0,1 --config ${P4RTDIR}/${DEFAULT_PROG}.p4runtime.txt,${P4RTDIR}/${DEFAULT_PROG}.json

