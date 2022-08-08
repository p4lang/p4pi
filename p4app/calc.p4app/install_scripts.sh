#! /bin/bash

CAL=$(docker ps|grep -m1 p4app_|awk '{print $1}')

docker cp cal.py $CAL:/scripts
