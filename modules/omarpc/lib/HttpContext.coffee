
##
##
##

module.exports = 

    class OmaRpcHttpContext extends floyd.http.Context
        
        ##
        ##
        ##
        configure: (config)->
            
            config = super new floyd.Config
                
                registry: {}
                
                data:
                    route: '/RpcServer'
                    authManager: 'sessions'
                    
            ,config
            
            @_IDENTITIES = {}
            
            (@_HIDDEN = config.data.hiddenMethods || []).push 'lookup', 'on', 'once', 'off', 'addListener', 'removeListener', 'forIdentity'
            
            @_registry = config.registry

            @_registry.System = 
            
                ##
                getInfo: (o, fn)=>
                
                    if arguments.length < 2
                        return o new Error 'no object name'
                    
                    if !@_registry[o]
                        return fn new Error 'unknown object '+o
                    
                    @_getObject o, (err, obj)=>
                        return fn(err) if err
                        
                        methods = []
                        for m, d of obj
                            if typeof obj[m] is 'function' && @_HIDDEN.indexOf(m) is -1
                                methods.push
                                    name: m
                    
                        fn null, methods: methods
                 
                ## fake methods
                login: ->
                logout: ->
            
            return config

                
        ##
        ##
        ##
        _createContent: (req, res, fn)->
                
            ##                
            if !(_ident = @_IDENTITIES[SID = req.session.SID])
                #console.log 'creating _ident'
                
                manager = new floyd.auth.Manager @_createAuthHandler()
                
                @_IDENTITIES[SID] = _ident = 
                    manager: manager
                    identity: manager.createIdentity @identity.id+'.'+SID
                
                req.session.on 'destroy', ()=>
                    _ident.manager.destroyIdentity _ident.identity
                    delete @_IDENTITIES[SID]
                
                manager.authorize req.session.TOKEN, (err)=>
                    @_createContent req, res, fn
                    
            else
                #console.log 'using _ident', _ident.identity.id

	            floyd.tools.http.parseData req, (err)=>
	                return fn(err) if err
	                
                    res.cache?.etag()
                    
                    ##
                    m = req.body.m
                    a = JSON.parse(req.body.a || '[]')
                    
                    a.push _send = (err, response)->
                        
                        obj =
                            response: response
                            error: if err then err.toString() else undefined
                    
                        res.ctype = 'application/json'
                        res.send JSON.stringify(obj)+'\n'
                    
                    ## login
                    if req.body.o is 'System' && m is 'login'
                        _ident.manager.login a[0], a[1], _send
                    
                    ## logout
                    else if req.body.o is 'System' && m is 'logout'
                        _ident.manager.logout _send
                        
                    ## find method
                    else
                        @_getObject req.body.o, (err, o)=>
                            return fn(err) if err
                            
                            if o.forIdentity
                                o.forIdentity _ident.identity, (err, wrapper)=>
                                    return fn(err) if err
                                
                                    wrapper[m].apply wrapper, a
                        
                            else o[m].apply o, a
                            
        ##
        ##
        ##           
        _getObject: (o, fn)->

            if typeof (obj = @_registry[o]) is 'string'
                @lookup obj, @identity, fn
                
            else fn null, obj
                
                