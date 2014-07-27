
##
fs = require 'fs'

##
path = require 'path'


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
    mkdir: (dir)->
        parts = normpath(dir).split('/'); 
        
        temp = '/'
        while parts.length > 0
            if !fs.existsSync( temp = path.join temp, parts.shift() )
                fs.mkdirSync temp
        
        return dir    
        
    
    ##
    ##
    exists: (name)->
    
        return fs.existsSync normpath name            
    
    
    ##
    ##
    stat: (name)->

        return fs.lstatSync normpath name            
    
    ##
    ##
    is_dir: (name)->
        
        files.stat(normpath name).isDirectory()
    
    ##
    ##
    list: (dir)->
        
        fs.readdirSync normpath(dir)            
    
    
    ##
    ##
    write: (name, data, enc='utf8')->
        
        fs.writeFileSync normpath(name), data, enc
    
    ##
    ##
    read: (name, enc='utf8')->
            
        fs.readFileSync normpath(name), enc
    
    
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
        
        if floyd.tools.objects.isArray name
            name = _join name
        
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
## private
##

##
##
##
normpath = (dir)->

    if typeof dir is 'object'            
        dir = _join dir
                    
    dir = dir.replace floyd.system.appdir, ''
    
    path.join floyd.system.appdir, path.normalize(dir)    

##
##
##
_join = (list)->
    list.join '/' 

    
##
## with node version 0.7.x there is a fs.existsSync and path.existsSync is deprecated
##
fs.existsSync ?= path.existsSync
path.existsSync = ()->
    fs.existsSync.apply fs, arguments


