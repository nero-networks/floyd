#!/bin/bash

cd $1

for dir in frontend backend
do
    if [ -d $dir ]
    then
        floyd create $dir
        cd $dir
        floyd build
        cd ..
    fi
done

chmod o-rw secrets.json */app.coffee
