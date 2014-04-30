

module.exports =

    ##
    ## Node Platform
    ##
    class NodePlatform extends floyd.AbstractPlatform
        
        ##
        ##
        constructor: (settings)->
            
            ## platform type
            settings.platform ?= 'node'
            settings.version = require(settings.libdir+'/package.json').version
            
            ## platform hostname
            settings.hostname = require('os').hostname()
            
            ## platform ident string
            settings.ident ?= 'NodeJS'
            settings.ident += ' ('+(p+'-'+v for p, v of process.versions).join(', ')+')'
            
            super settings            
            
            
        ##
        ##
        ##
        boot: ()->
            
            _dirs = [@system.libdir]
            
            if @system.appdir isnt @system.libdir
                _dirs.push @system.appdir 
                
            
            ## load lib
            
            #console.log 'loading lib', _dirs, @
            floyd.tools.libloader _dirs, @, 
                
                ##
                platform: @system.platform
                
                
                ##
                package: (target, name, path)->
                    try
                        target[name] ?= require path
                    catch e
                        #if e.code isnt 'MODULE_NOT_FOUND' ## > node 0.7
                        if !e.message.match 'Cannot find module'
                            console.error 'Packaging FATAL', e.stack||e

                        
                ##
                module: (target, name, path)=>
                
                    target[name] ?= null            		

                    #console.log name, path
                                        
                    ## getter delegation delays the require 'till its really needed
                    Object.defineProperty target, name,
                        get: ()->                        	
                            try 
                                require path 
                            catch e
                                console.error 'error in file '+path
                        set: ()->
                            #console.log 'reset', path
                        
            ##
            return @
            
                                        
        ##
        ##
        init: (config, fn)->
        
            ##
            ## prepare a simple error logger if fn isn't present
            fn ?= (err)=>
                if err
                    if config?.error
                        config.error err
                        
                    else 
                        console.error err.stack||err.message||err 
            
            ##
            ## resolve config if config is a named reference
            if typeof config is 'string' 
                if config.match /[\/\\]/
                
                    config = require floyd.tools.files.path.join @system.appdir, config
                    
                else
                    config = objects.resolve config
            
            
            ##
            ## read app config from file if found
            if !config
                try
                    
                    config = require floyd.tools.files.path.join @system.appdir, './app'
                                        
                catch e
                    if e.code isnt 'MODULE_NOT_FOUND'
                        fn e
            
            ##
            ## create an empty object if config is still absent
            config ?= {}

            ##
            ## set the default ip to appname
            if !config.id
                config.id = @system.appdir.split('/').pop()
            
            
            if !config.UID || !config.GID
                stat = floyd.tools.files.stat '.'
                config.UID ?= stat.uid
                config.GID ?= stat.gid                          
            
            @system.UID = config.UID
            @system.GID = config.GID
            
            ##
            ## extend floyd.system with settings from config
            if config.system
            	floyd.tools.objects.extend floyd.system, config.system
            
            files = floyd.tools.files            
            ## create tmp folder and remove on exit
            @system.tmpdir ?= files.path.join '.floyd', 'tmp'
            
            files.mkdir @system.tmpdir
            
            ##
            process.on 'exit', ()=>
                
                for _file in files.list @system.tmpdir
                    file = files.path.join @system.tmpdir, _file
                    
                    if files.exists file
                        files.rm file, true
            
        
            ##
            ## create and start Context instance
            ctx = super config, fn
            
            ## never run the floyd with UID == 0 exept you know (and understand) why
            ##
            ## If started as root or with sudo the user and group IDs
            ## of the process are resetted to the configured UID/GID.
            ##
            ## If either UID or GID or both are not set the UID/GID
            ## which own the app directory are used. 
            ##
            ## CAVEAT: The process will continue to run privileged 
            ##         if the app directory belongs to root(:root)
            ##         and nothing else is configured!
            ##
            ctx.on 'after:booted', ()=>

                if process.getuid() is 0
                    
                    ## chown tmpdir
                    floyd.tools.files.chown @system.tmpdir, @system.UID, @system.GID
                    
                    ## chown process
                    process.setgid(@system.GID) # GID first ;-)
                    process.setuid(@system.UID)
                    
                    ## EXPERIMENTAL! --> delete the require cache to prevent
                    ## unprivileged users from reading sensitive data
                    ## out of previously required module exports.
                    
                    ## I decided to delete everything to be sure at all.
                    ## I messured the startup time with and without the cache 
                    ## the overhead is about 55 to 60 milliseconds, tollerable in my oppinion
                    
                    #___start = +new Date()
                    
                    for id, mod of require.cache                                    	
                        delete require.cache[id]
                    
                    #ctx.on 'after:running', ->
                    #	console.log (+new Date()) - ___start, 'millis'
                    
                    ## <-- EXPERIMENTAL
                    
                else if (@system.UID && @system.UID isnt process.getuid()) || (@system.GID && @system.GID isnt process.getgid())
                    ctx.logger.warning 'WARNING: running unprivileged!'
                    ctx.logger.warning '         changing UID/GID to %s/%s is impossible', (@system.UID || @system.GID), (@system.GID || @system.UID)
                    ctx.logger.warning '         current UID/GID settings: %s/%s', process.getuid(), process.getgid()
                    
                         
            ##
            ## prepare shutdown
            stopped = !ctx.stop
            destroyed = !ctx.destroy
            exited = false
            
            ## shutdown recursive on exit
            shutdown = (err)=>
                fn(err) if err
                
                ##
                if !stopped && stopped = true
                    ctx.stop shutdown
                
                ##
                else if !destroyed && destroyed = true
                    ctx.destroy shutdown
                    
                else if !exited && exited = true
                    process.exit()
            
            
            process.on 'SIGINT', ()=> shutdown()
            process.on 'SIGTERM', ()=> shutdown()
            process.on 'exit', ()=> 
                shutdown() if !exited && exited = true
            
            ##
            ## async return! ctx is not booted yet...
            ##	
            return ctx
        
        
