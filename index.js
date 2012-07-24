/*
    Node.js Platform setup
*/

// link the coffee-script compiler into the require toolchain
require('coffee-script'); 

// re-wire some signals
process.on('SIGKILL', function() { process.exit(1) });
process.on('SIGINT', function() { process.exit() });
process.on('SIGTERM', function() { process.exit() });    

// Catch uncaught errors
process.on('uncaughtException', function(err) {                    
    console.error(err.stack||err);
});

// boot the node platform

floyd = {AbstractPlatform: require('./lib/AbstractPlatform')}
floyd.Platform = require('./platforms/node/lib/Platform');

module.exports = floyd = new floyd.Platform({
    libdir: __dirname, 
    appdir: process.cwd()
});

floyd.tools = {
    objects: require('./tools/objects'),
    files: require('./platforms/node/tools/files'),
    libloader: require('./platforms/node/tools/libloader')
};

floyd.boot();
