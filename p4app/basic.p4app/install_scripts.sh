#! /bin/bash

CAL=$(docker ps|grep -m1 p4app_|awk '{print $1}')
docker cp send.py $CAL:/scripts
docker cp receive.py $CAL:/scripts
echo "Done"
