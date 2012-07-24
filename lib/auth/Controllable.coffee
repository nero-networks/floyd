
module.exports = 

    ##
    ## @class floyd.auth.Controllable
    ##
    class Controllable

        ##
        ##  
        ##
        constructor: (@ID, @parent)->
            
            @_hiddenKeys = ['constructor', 'identity', 'parent', 'logger', 'destroy']
                        
            @logger = @_createLogger @ID
            
            @identity = @createIdentity()
            
            for k, fn of @
                if typeof fn is 'function'
                    fn.identity = @identity		
                        
            

        ##
        ##
        ##
        destroy: (done)->
            #@logger.info 'destroy', @identity.id
            @_getAuthManager().destroyIdentity @identity, done
            
        ##
        ##
        ##
        _createLogger: (id)->
            
            new floyd.logger.Logger id
            

        ##
        ## 
        ##
        createIdentity: (id)->
            if @identity
                id = @identity.id+'.'+id
            else 
                id = @ID
            
            #@logger.debug 'createIdentity', id
            @_getAuthManager().createIdentity id
        
        
            
        ##
        ##
        ##
        _getAuthManager: ()->
            if !( manager = @parent?._getAuthManager?() ) 
                manager = @__authManager ?= @_createAuthManager() 
        
            return manager
            
                
        ##
        ##
        ##
        _createAuthManager: ()->
            if !( manager = @parent?._getAuthManager?() )
                manager = new floyd.auth.Manager @_createAuthHandler()

            return manager
            
        ##
        ##
        ##
        _createAuthHandler: ()->
            new floyd.auth.Handler()
        
        ##
        ## @param identity - 
        ##
        forIdentity: (identity, fn)->

            @logger.debug 'forIdentity', identity.id
            
            @_allowAccess identity, (err)=>
                return fn(err) if err	
                
                @logger.debug 'allowed access for', identity.id
                
                ## calls _permitAccess with the current identity
                _checkAccess = (key, args=[], ok)=>
                    @_permitAccess identity, key, args, (err)=>	
                        if err
                            if typeof (fn = args.pop()) is 'function'
                                fn err
                            else
                                throw err
                                
                        else ok()
                
                wrapper = {}
                
                ##				
                floyd.tools.objects.process @,
                    
                    ##
                    each: (key, value, next)=>
                        
                        if key.charAt(0) isnt '_' && @_hiddenKeys.indexOf(key) is -1
                        
                            if typeof value is 'function'							
                                
                                wrapper[key] = (_args...)=>
                                    
                                    _checkAccess key, _args, ()=>
                                        
                                        ## EXPERIMENTAL bind the identity to the method... 
                                        
                                        value.identity = identity
                                        
                                        try					
                                            res = value.apply @, _args
                                        catch err
                                            if typeof (_fn = _args.pop()) is 'function'
                                                _fn err												
                                            
                                        value.identity = @identity
                                        
                                        return res
                                
                            else
                                
                                wrapper[key] = value
                        
                        
                        next()
                
                
                    ##
                    done: (err)=>
                        return fn(err) if err
                        
                        fn null, wrapper
                        
                        
        
        ##
        ##
        ##
        _allowAccess: (identity, fn)->
            @logger.debug '_allowAccess', identity.id
            @_getAuthManager().authenticate identity, fn
                
            
            
            
        ##
        ##
        ##
        _permitAccess: (identity, key, args, fn)->

            fn null, key.charAt(0) isnt '_' && @_hiddenKeys.indexOf(key) is -1
