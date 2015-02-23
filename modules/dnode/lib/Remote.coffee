
module.exports = 

    class DNodeRemote extends floyd.Context
        
        ##
        ##
        ##
        _useProxy: (proxy)->      
            
            ##
            if !@_proxy 
                @_proxy = proxy
                
                ## prepare __wrappers
                @__wrappers = {}                 
                
                ## reset the id
                @ID = @parent.ID + '.' + (@id = @_proxy.id)
            
                ## recreate the logger
                @logger = @_createLogger @ID
                
            else
                @_proxy = proxy
                
                ##
                ## rewrap active lookups
                for name, wrappers of @__wrappers
                    do(name, wrappers)=>
                
                        for id, wrapper of wrappers
                            do(id, wrapper)=>
                                
                                @lookup name, wrapper.identity, (err, ctx)=>
                                    return wrapper.error(err) if err

                                    for key, value of ctx 
                                        wrapper.ctx[key] = value
            
                                    
        
        ##
        ##
        ##
        lookup: (name, identity, fn, noremote)->
            
            if noremote
                #console.log '%s direct lookup %s for %s', @ID, name, identity.id
                
                super name, identity, fn
                
            else
                #console.log @id, 'proxy lookup', name
                
                @_proxy.lookup name, identity, (err, ctx)=>
                    return fn(err) if err
                    
                    fn null, @_wrapRemote name, identity, ctx, fn
                
                , true ## <-- this is the noremote flag
                         
        
         
        ##
        ##
        ##
        _wrapRemote: (name, identity, ctx, error)->         

            wrappers = @__wrappers[name] ?= {}                      
            wrapper = wrappers[identity.id] ?=
                error: error
                identity: identity
                ctx: {}
                
            for key, value of ctx 
                wrapper.ctx[key] = value
            
            return wrapper.ctx

