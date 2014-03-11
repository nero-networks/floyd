        
            
module.exports = 

    ## 
    ## @class floyd.AbstractPlatform
    ##
    ## The foundation on which Contexts are running.
    ## The first Floyd Object instanciated while booting is floyd.Platform. 
    ## This class must be implemented per platform! 
    ## take a look into ./platforms/*/lib/Platform.*
    ##
    class AbstractPlatform 
        
        ##
        ##
        ##	
        constructor: (settings)->
            
            @system = settings 
            
            @system.platform ?= 'unknown'
            @system.ident ?= 'unknown'
            @system.os ?= process?.platform || 'unknown'
            
            @system.hostname ?= 'unknown'
            
            @system.errors ?= 
                max: 5
            
            @system.errors.instances ?= []
        
        ##
        ##
        boot: ()->
            return @
        
                
        ##
        ## configure, prepare and start a new root-context
        ##
        init: (config, fn)->

            if typeof config is 'string'
                config = _resolve config			
            
            config.type ?= 'floyd.Context'
            
            #console.log 'starting', config, floyd
            
            ##
            if typeof config.type is 'function'
                ctor = config.type
                config.type = ctor.name||'DynContext'
            
            else if !(ctor = _resolve config.type)
                throw new Error 'unknown type: '+config.type
                            
            
            fn ?= (err)->
                console.error('platform error:', err) if err				
            
            ctx = new ctor()
            
            ctx.init new floyd.Config(config), (err)=>
                return fn(err) if err
                
                if config.NOBOOT || !ctx.boot
                    #console.log 'no boot...'
                    fn null, ctx
                    
                else
                    #console.log 'booting...'
                    ctx.boot (err)=>
                        return fn(err) if err
                        
                        if config.NOSTART || !ctx.start
                            #console.log 'no start...'
                            return fn null, ctx
                        
                        else
    
                            errors = @system.errors							
                            
                            _started = false
                            
                            process.nextTick ()=>

                                ctx.start (err)=>
                                    if !err && !_started && ( _started = true )
                                        return fn(null, ctx) 
                                    
                                    if errors.instances.length < errors.max
                                        errors.instances.push err
                                        fn err
                                    
                                    else if errors.instances.length is errors.max
                                        errors.instances.push err = new Error 'too many errors! stopping log...'
                                        
                                        fn err
                                    
                                    else if ctx.data.debug
                                        console.warn 'suppressed error', err.message
            
            ##
            ## async return... ctx is not booted yet
            #console.log 'returning...'
            return ctx

        
##
##
##
_resolve = (name)->
    if (obj = floyd.tools.objects.resolve name)
        return obj
        
    try
        obj = require name
        
    catch e	