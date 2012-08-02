
dnode = if typeof DNode isnt 'undefined' then DNode else require('dnode')

module.exports = 

    class DNodeBridge extends floyd.Context
        
        
        ##
        ##
        ##
        configure: (config)->

            ##
            ##
            config = super new floyd.Config
            
                data:
                    ports: []
                    gateways: (if floyd.system.platform is 'remote' then [{}] else [])

            , config 
            
            
            ## hack to delegate lookups to origin 
            
            if origin = config.ORIGIN
            
                floyd.tools.objects.intercept @, 'lookup', (name, identity, fn, lookup)=>
                    
                    #console.log 'lookup', name, origin
                    
                    lookup name, identity, (err, ctx)=>					
                        if ctx
                            fn(null, ctx)
                        
                        else
                            lookup origin+'.'+name, identity, fn
                    
                

            ## hack to connect us before our children are booted 
            
            floyd.tools.objects.intercept @, 'boot', (done, boot)=>
            
                @_connect (err)=>
                    return done(err) if err
                    
                    ##		
                    if config.TOKEN
                        @_getAuthManager().authorize config.TOKEN
                        
                    @_listen (err)=>
                        return done(err) if err
                        
                        boot done 

            return config	
    
    
        ##
        ##
        ##
        _connect: (fn)->
            done = false
            
            @_process @data.gateways, 
                
                #done: fn
                
                ## --> TEMPORARY DEBUGGING remove the following after it is made 
                ##     absolutely clear that it never gets called twice without an error.
                ## 
                ##     don't forget to comment in the above done: fn (!!!)
                ##
                ##     its also save to remove the done = false statement at the beginning of _connect
                ##
                done: (err)=>
                    return fn(err) if err
                    
                    if !done && ( done = true )
                        fn()
                        
                    else
                        console.log 'doppelt!'				
                ## <-- TEMPORARY DEBUGGING 
                                
                each: (conf, next)=>
                    @logger.info 'connecting to gateway:', conf	 
                    
                    first=false
                    
                    connected = (err)=>
                        return next(err) if err
                        
                        if !first && ( first = true )
                            next()
                            
                        else
                            @logger.debug 'reconnected', conf
                            
                            @_emit 'reconnect', conf
                    
                        
                    
                    @_createLocal(connected).connect conf,
                        'sync disconnect on unload': false
                                                
        
        ##
        ##
        ##
        _listen: (fn)->
        
            @_process @data.ports, 
                        
                done: fn
                
                each: (conf, next)=>
                    @logger.info 'listening on port:', conf
                        
                    handler = (err)=>
                        fn(err) if err
                    
                    if conf.parent
                        
                        parent = @parent
                        while parent && !(server = parent.server) && parent.parent
                            parent = parent.parent
                         
                        @_createLocal(handler).listen 
                            server: parent.server
                            webserver: true
                
                    else if conf.child 
                        
                        @_createLocal(handler).listen 
                            server: @children[conf.child]
                            webserver: true
                    
                    else if conf.ctx
                        
                        @lookup conf.ctx, @identity, (err, ctx)=>
                            @_createLocal(handler).listen 
                                server: ctx.server
                                webserver: true
                        
                    else
                        @_createLocal(handler).listen conf	
                    
                    ##
                    next()
            
        ##
        ##
        ##
        _createLocal: (fn)->
            
            ##
            dnode (proxy, conn)=>

                @_createRemote proxy, conn, fn
        
        
        ##
        ##
        ##
        _createRemote: (proxy, conn, fn)->
            
            ##
            root = @parent || @
            
            ##
            child = new floyd.dnode.Remote (id:conn.id, type:'dnode.Remote'), root

            ##			
            child.boot (err)=>
                return fn(err) if err
            
                ##
                _first = false	
                conn.on 'remote', (remote)=>
                    
                    #console.log child.ID, 'conn remote', conn.id

                    child._useProxy remote
                    
                    #console.log 'add %s to %s', child.ID, root.ID
                    
                    root.children.push child
                    
                    child.start (err)=>
                        return fn(err) if err
                        
                        if !_first && ( _first = true )
                            fn() 
                                
                    
                ##
                conn.on 'end', ()=>
                    
                    #console.log child.ID, 'conn end', conn.id
                    
                    child.stop (err)=>
                    
                        root.children.delete child

                        #console.log 'conn destroy'
                        child.destroy fn

                            
                ##
                conn.on 'error', (err)=>
                    
                    console.log 'conn error!', err
                    
                    fn err			
                            
                                
            ## remote api
            
            ID: child.ID

            lookup: (args...)=> child.lookup.apply child, args
            
            ping: (fn)->
                fn new Date()
