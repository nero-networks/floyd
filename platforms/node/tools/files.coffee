
##
fs = require 'fs'

##
path = require 'path'

##
zlib = require 'zlib'


##
##
##
module.exports = files =
    
    ##
    fs: fs

    ##
    path: path
    
    ##
    ##
    appdir: (args...)->
        
        normpath args


    ##
    ##
    mkdir: (dir)->
        parts = normpath(dir).split('/'); 
        
        temp = '/'
        while parts.length > 0
            if !fs.existsSync( temp = path.join temp, parts.shift() )
                fs.mkdirSync temp
        
        return dir    
        
    
    ##
    ##
    exists: (name, fn)->
        if fn
            fs.exists normpath(name), fn
        
        else fs.existsSync normpath name            
    
    
    ##
    ##
    stat: (name, fn)->
        if fn
            fs.lstat normpath(name), fn
        
        else fs.lstatSync normpath name            
    
    ##
    ##
    is_dir: (name, fn)->
        if fn
            files.stat name, (err, stat)->
                fn err, stat?.isDirectory()
                
        else files.stat(name).isDirectory()
    
    ##
    ##
    list: (dir, fn)->
        if fn
            fs.readdir normpath(dir), fn
            
        else fs.readdirSync normpath(dir)            
    
    
    ##
    ##
    write: (name, data, enc='utf8', fn)->
        if fn
            fs.writeFile normpath(name), data, enc, fn
            
        else fs.writeFileSync normpath(name), data, enc
    
    ##
    ##
    read: (name, enc='utf8', fn)->
        if fn
            fs.readFileSync normpath(name), enc, fn
            
        else fs.readFileSync normpath(name), enc
    
    
    ##
    ##
    cp: (srcFile, destFile) ->
        buff = new Buffer BUF_LENGTH = 64*1024
         
        fdr = fs.openSync srcFile, 'r' 
        fdw = fs.openSync destFile, 'w'
         
        bytesRead = 1
        pos = 0
        while bytesRead > 0
          bytesRead = fs.readSync fdr, buff, 0, BUF_LENGTH, pos 
          fs.writeSync fdw,buff,0,bytesRead 
          pos += bytesRead
          
        fs.closeSync fdr 
        fs.closeSync fdw 
        
    
    ##
    ##
    mv: (old_name, new_name...)->
        
        #console.log 'move\n\t%s\nto\n\t%s', normpath(old_name), normpath(new_name)
        
        fs.renameSync normpath(old_name), normpath(new_name)
    
    
    ##
    ##
    rm: (name, recursive)->
        
        name = normpath name
        
        if files.exists name
            if files.is_dir name
                if recursive
                    for file in files.list name
                        files.rm [name, file], true
                
                fs.rmdirSync name
            
            else
                fs.unlinkSync name
                            
    ##
    ##
    chown: (name, uid, gid)->
    
        fs.chownSync normpath(name), uid, gid
        
    
    ##
    ##
    chmod: (name, mode)->
    
        fs.chmodSync normpath(name), mode
        
    
    ##
    ## tmp files
    tmp: (name, suffix)->
        name ?= floyd.tools.strings.uuid()
        
        if suffix
            name = name+'.'+suffix

        ##
        normpath [floyd.system.tmpdir, name]

    
    ##
    ## watch files
    watch: (name, options, fn)->        
    
        ## TODO huch?? warum werden die options nicht verwendet??
        
        if typeof options is 'function' 
            fn = options 
            options = 
                persistent: false  
            
        fs.watch normpath(name), fn
    
    ##
    ##
    gzip: (name, fn)->
        name = normpath(name)
        
        gzip = zlib.createGzip()
        inp = files.fs.createReadStream name
        out = files.fs.createWriteStream name+'.gz'
        
        out.on 'close', ()->
            files.rm name
            fn?()
        
        inp.pipe(gzip).pipe(out);

    ##
    ##
    gunzip: (name, fn)->
        name = normpath(name)

        gunzip = zlib.createGunzip()
        inp = files.fs.createReadStream name
        out = files.fs.createWriteStream name.substr 0, name.length-3
        
        out.on 'close', ()->
            files.rm name
            fn?()
        
        inp.pipe(gunzip).pipe(out);


##
## private
##

##
##
##
normpath = (dir)->

    if typeof dir is 'object'            
        dir = path.join.apply path, dir
    
    dir = dir.replace floyd.system.appdir, ''
    
    path.join floyd.system.appdir, path.normalize(dir)    


    
##
## with node version 0.7.x there is a fs.existsSync and path.existsSync is deprecated
##
fs.existsSync ?= path.existsSync
path.existsSync = ()->
    fs.existsSync.apply fs, arguments


