#!/bin/bash

echo "Stopping T4P4S switch..."

screen -X -S switch quit >> /dev/null

echo "Launching T4P4S switch with the default program"

pushd /home/pi/p4pi/t4p4s/t4p4s >> /dev/null
screen -dmS switch bash -c "source ~/.bashrc;PYTHON3=python3.9 ./t4p4s.sh :l2switch p4rt;/bin/bash"
popd

