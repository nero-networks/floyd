#!/bin/bash

cd $1

for dir in *
do
    if [ -d $dir ]
    then
        floyd create $dir
        cd $dir
        floyd build
        cd ..
    fi
done
