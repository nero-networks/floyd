#!/bin/bash

##
## floyd-build hookup script
##

echo copying node_modules patches
cp -b -r node_modules_patches/* node_modules/

