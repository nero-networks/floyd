
module.exports = 

    class DNodeRemote extends floyd.Context
        
        ##
        ##
        ##
        _useProxy: (@_proxy)->		
            
            ##
            if !@origin
            
                @origin = 
                    dnode: @id
                    proxy: @_proxy.ID
                
                ## prepare __wrappers
                @__wrappers = {} 
                
                
                ## reset the id
                @ID = @parent.ID + '.' + (@id = floyd.tools.strings.part @_proxy.ID, '.', -2)
            
                ## recreate the logger
                @logger = @_createLogger @ID
                
                ## recreate the identity
                #console.log 'recreate the identity'
                #manager = @_getAuthManager()
                #manager.destroyIdentity @identity
                #
                #@identity = manager.createIdentity @ID
                    
            else
            
                ##
                ##
                @origin.proxy = @_proxy.ID
                
                ##
                ##
                for name, wrappers of @__wrappers
                    do(name, wrappers)=>
                
                        for id, wrapper of wrappers
                            do(id, wrapper)=>
                                
                                @lookup name, wrapper.identity, (err, ctx)=>
                                    return wrapper.error(err) if err
                                    
        
        ##
        ##
        ##
        lookup: (name, identity, fn, noremote)->
            
            if noremote
            
                super name, identity, fn
                
            else
                #console.log @id
                @_proxy.lookup name, identity, (err, ctx)=>
                    return fn(err) if err
                    
                    fn null, @_wrapRemote name, identity, ctx, fn
                
                , true
                         
        
         
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
            
            wrapper.stop = ()=>
                console.log 'TODO: pseudo stop ', name
            
            wrapper.destroy = ()=>
                console.log 'TODO: pseudo destroy ', name
            
            return wrapper.ctx
                
            
                