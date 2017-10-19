/*
    Node.js Platform setup
*/

// link the coffeescript compiler into the require toolchain

require('coffeescript/register');

// EXPERIMENTAL coffeescript compiler cache -->
var CoffeeScript = require('coffeescript'),
    fs = require('fs'), path = require('path'),
    cachedir = path.join('.floyd', 'coffeecache'),
    cachedbfile = path.join(cachedir, 'cachedb.json'),        
    cachedb = {}, timeout;

if(fs.existsSync(cachedir)) {
    if(fs.existsSync(cachedbfile)) 
        cachedb = JSON.parse(fs.readFileSync(cachedbfile));
    
    require.extensions['.coffee'] = function (module, filename) {
        var filestr = filename.replace(/[\/\\]/g, '$'),
            cachefile = path.join(cachedir, filestr)+'.js',
            stats = fs.lstatSync(filename), code;
        
        if(!fs.existsSync(cachefile) || !cachedb[filestr] || cachedb[filestr] < +stats.mtime) {    
            code = CoffeeScript._compileFile(filename, false);
            fs.writeFile(cachefile, code);                

            cachedb[filestr] = +stats.mtime;

            if(!timeout) 
                timeout = setTimeout(function() {
                    fs.writeFile(cachedbfile, JSON.stringify(cachedb));
                    timeout = null;
                }, 5000);
            
        } else 
            code = fs.readFileSync(cachefile).toString();
        
        return module._compile(code, filename);
    }
}
// EXPERIMENTAL coffeescript compiler cache <--

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
