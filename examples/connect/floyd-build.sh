#!/bin/bash

cd $1

test -x node_modules || mkdir node_modules

test -x node_modules/connect || npm i connect
