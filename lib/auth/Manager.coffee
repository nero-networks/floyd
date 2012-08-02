
events = require 'events'

module.exports = (handler)->
    
    ##
    ##
    pool = {}
    
    ##
    ##
    __token = null
    
    ##
    ##
    __user = null
    
    ##
    ##
    handler ?= new floyd.auth.Handler()
    
    ##
    ##
    manager = new events.EventEmitter()
    manager.setMaxListeners 100

    ##
    ##
    _on = manager.addListener
    manager.addListener = (action, listener)->
        _on.apply manager, arguments
        
        if action is 'login' && __user
            listener __user
            
        if action is 'authorized' && __token
            listener __token
            
            
    ##
    ##
    ##
    authorize: __authorize = (token, fn)->
        manager.emit 'authorizing', __token = token
        
        #console.log 'authorizing', __user, handler.x
        
        handler.authorize token, (err, user)=>
            #console.log 'post authorizing', user
            
            if !err && __user = user
                #console.log 'authorized user', user
            
                manager.emit 'login', __user 
        
            #else if err
            #	console.log 'authorize error', err
            
            fn? err 
    
    ##
    ##
    ##
    createIdentity: (id)->
        #console.log floyd.tools.objects.keys(pool).length, 'create', id
        
        if !pool[id]
            return pool[id] = new floyd.auth.Identity id, manager			
            
        else
            throw new Error 'duplicate identity: '+id
    
    
   ##
    ##
    ##
    destroyIdentity: (identity, done)->
        id = identity.id
        
        if pool[id] 
            delete pool[id]
            
            #console.log floyd.tools.objects.keys(pool).length, 'destroy', id
            
            if manager.emit
                manager.emit 'destroy:'+id
            
        else
            console.warn 'unmanaged identity', id 

        done?()
        

    ##
    ##
    ##
    login: (user, pass, fn)->
        handler.login __token, user, pass, (err)=>
            #console.log 'LOGIN:', user
            return fn(err) if err 
            
            __authorize __token
            
            if fn
                process.nextTick ()=>
                    fn null, true
             
    
    
    
    ##
    ##
    ##
    logout: (fn)->
        manager.emit 'logout'

        __user = null
        
        handler.logout __token, fn

        
    ##
    ##
    ##	
    authenticate: (identity, fn)->
        
        if pool[identity.id] is identity
            #console.log 'authentic local identity', identity.id
            fn()
        
        else
            #console.log 'try handler for identity', identity.id
            handler.authenticate identity, fn
        