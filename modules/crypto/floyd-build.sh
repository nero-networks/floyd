#!/bin/bash

##
## floyd-build hookup script
##

MODULE=$1

cd $MODULE

SOURCE="components/"

TARGET="tools/CryptoJS.js"

ZIPFILE="http://code.google.com/p/crypto-js/downloads/detail?name=CryptoJS%20v3.0.2.zip"

lastmod=$(date -d @$(find $SOURCE -type f -printf '%A@\t%p\n' | sort -r -k1 | head -n1 | cut -f1) +%s)

curr=0
test -e $TARGET && curr=$(date -d @$(find $TARGET -type f -printf '%A@\t%p\n'|cut -f1) +%s)

if [ $curr -lt $lastmod ]
then

    echo "creating $MODULE/$TARGET"
    
    test -e $TARGET && rm $TARGET
    
    (cd $SOURCE
    
    echo -e "/*\n * DON'T EDIT THIS FILE! \n *\n * fetch a copy of crypto-js from here\n * $ZIPFILE\n * and update ./modules/crypto/components/* with the components of your choice,\n * then run floyd build\n *\n */"  

    echo -e "\n(function() {"
    
    cat core.js
    
    for file in $(find ./modules -type f)
    do
        echo -e "\n\n\n/* $file */\n\n"
        
        cat $file
        
    done
    
    cat evpkdf.js cipher-core.js
    
    for file in $(find ./cipher -type f)
    do
        echo -e "\n\n\n/* $file */\n\n"
        
        cat $file
        
    done
    
    echo -e "\nmodule.exports = CryptoJS;"	
    
    echo "}());") > $TARGET

fi
