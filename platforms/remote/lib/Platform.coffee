
__MODULES__ = null

module.exports =

    class RemotePlatform extends floyd.AbstractPlatform
        
        ##
        ##
        ##
        constructor: (base)->
            for key, value of base
                @[key] = value
                        
            settings = @system || {}		
            
            ## platform type
            settings.platform = 'remote'
            
            ## platform ident string
            settings.ident = navigator?.userAgent || 'RemotePlatform'
            
            ## os type
            if (_probe = (navigator?.oscpu || 'unknown')).match /[L]inux/
                settings.os = 'linux'
            
            else if _probe.match /[Ww]in/
                settings.os = 'win'
                
            else
                settings.os = _probe
            
            super settings
            
            window.process ?=
                nextTick: (fn)->
                    setTimeout fn, 1

        
        ##
        ##
        ##
        boot: (modules, attempt=0)->			
            __MODULES__ ?= modules
            
            if !modules && !attempt
                modules = __MODULES__
                
                    
            delayed = {}		
            
            err = null
            for path, init of modules
                do(path, init)=>
                    
                    _list = path.split('.')
                    _list.shift()
                        
                    _root = @
                    name = _list.pop()
                    
                    ## find/create the package container
                    if _list.length > 0
                        for part in _list
                            _root = _root[part] ?= {}
                    
                    
                    try	
                        ## 1. collect subpackages that may already be loaded
                        pre = _root[name] || {}
                        
                        ## 2. initialize the package
                        mod = _root[name] = init()
                        
                        ## 3. relocate eventualy loaded subpackages into the package 
                        for k, v of pre
                            if !mod[k]
                                mod[k] = v
                        
                        #console.log 'build class', path, _list, part, _root
                    
                    catch e
                        err = e
                        delayed[path] = init
            
            if ++attempt < 10 && _count = floyd.tools.objects.keys(delayed).length
                #console.log 'delayed build', err, delayed
                
                @boot delayed, attempt
                
            else if err
                throw err
            
            return @
            