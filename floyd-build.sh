#!/bin/bash

##
## floyd-build hookup script
##

echo copying node_modules patches
cp -b -r node_modules_patches/* node_modules/

chmod -R ugo+r node_modules/backoff/

cd node_modules
ln -s @davedoesdev/dnode dnode
cd ..
