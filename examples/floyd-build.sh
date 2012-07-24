#!/bin/bash

function build() {
    for dir in */.floyd
    do
        test -x $dir/logs || (mkdir $dir/logs; touch $dir/logs/stdout.log)
        test -x $dir/tmp || (mkdir $dir/tmp; chmod ugo+rx $dir/tmp)
    done
}

cd $1
build

cd cluster
build

