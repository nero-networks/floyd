
events = require 'events'

ACTIONS = ['configured', 'booted', 'started', 'running', 'shutdown', 'stopped', 'message']

LOOKUPS = {}

module.exports = 

    ## 
    ## @class floyd.Context
    ##
    ## The floyd.Context is the central class in this project.
    ## It is used as the base-class for all Floyd Context implementations.
    ##
    ## TODO Livecycle
    ##
    ## construct -> start -> stop
    ##
    class FloydContext extends floyd.auth.Controllable
        
        
        ## 
        ## TODO configuration procedure documentation
        ##
        ## * id
        ## * data (defaults + config)
        ## * children
        ## * parent
        ##
        constructor: (config={}, @parent)->			
            @_status = 'unconfigured'
            
            config = @configure config

            @id = config.id
                    
            @ID = if !(@parent?.ID) then @id else @parent.ID+'.'+@id
            
            if typeof (@type = config.type) is 'function'
                @type = @ID+'.'+(@type.name || 'DynContext')					
            
            @data = new floyd.data.SearchableMap config.data, @parent?.data
            
            super @ID, @parent
            
            @_emitter = @_createEmitter config
            
            @_hiddenKeys.push 'configure', 'boot', 'start', 'stop', 'delegate', 'data', 'parent', 'children'
            
            @children = new floyd.data.MappedCollection()

            @_changeStatus 'configured'

            @_process config.children,
                
                each: (child, next)=>
                    
                    @_createChild child, next			
                        
                done: (err)=>
                    
                    @logger.error(err) if err				


        ##
        ##
        ##
        _createChild: (config, done)->
            if typeof (ctor = config.type) isnt 'function'
                ctor = floyd.tools.objects.resolve(ctor || 'floyd.Context')
                
            if ctor 
                @children.push ctx = new ctor config, @
        
                done null, ctx
                
            else
                done new Error 'Unknown Context-Type: '+config.type


        ##
        ##
        __ctxID: ()->
            if @parent?.__ctxID
                @parent.__ctxID()
            else
                @__CTXID ?= 0
                'ctx'+(@__CTXID++)
    
        ##
        ## base configuration
        ##		
        configure: (config)->
            
            if typeof config is 'string'
                config = new floyd.Config floyd.tools.objects.resolve config
            
            config.id ?= @__ctxID()
            
            config.type ?= 'floyd.Context'
            
            config = new floyd.Config config
            
            ## extend with methods from config. add @method._super for each
            for key, value of config
                do(key, value)=>
                    if typeof value is 'function'

                        _orig_super = @[key]
                                    
                        @[key] = (args...)=> 
                            value.apply @, args
                        
                        if _orig_super 
                            @[key]._super = (args...)=> 
                                #console.log 'calling _orig_super for', key, _orig_super.toString()
                                _orig_super.apply @, args
            
            
            _destroy = @destroy
            @destroy = (done)=>
            
                if @stop && @_status isnt 'stopped'
                    return @_logger.warn 'context not stopped!'
                
                @_init 'destroy', null, (err)=>
                    done(err) if err					

                    _destroy.call @, (err)=>
                        @_changeStatus 'destroyed'	
                            
                        done err
            
            
            if manager = config.data.authManager
                
                if config.ORIGIN
                    manager = config.ORIGIN+'.'+manager
                
                #console.log 'prepare _createAuthHandler', manager
                
                __user = config.USER
                
                ##
                @_createAuthHandler = ()=>
                    
                    #console.log '_createAuthHandler', manager, __user
                    
                    _auth = (fn)=>
                        ## EXPERIMENTAL shortcut. use child if found
                        ## re-think implications of unprotected usage
                         
                        if (ctx = @children[manager]) 
                            fn null, ctx
                        
                        else 
                            @lookup manager, @identity, fn
                    
                    new floyd.auth.Handler

                        ##
                        authorize: (token, fn)=>
                            
                            #console.log 'autorizazion request', __user, @id
                            
                            if !@identity
                                #console.log 'authorized user', __user.login
                                
                                fn null, __user

                            else
                                #console.log 'using manager for authorize'
                                _auth (err, auth)=>
                                    return fn(err) if err

                                    #console.log 'delegate authorize', identity.id
                                    auth.authorize token, (err, user)=>
                                            
                                        fn err, __user = user
                            
                        ##
                        authenticate: (identity, fn)=>
                            #console.log 'using manager for authenticate', identity.id
                            
                            _auth (err, auth)=>
                                if err || !auth
                                    @logger.warning 'authentication failed!\n\terror: %s\n\tfor: %s', \
                                        (err?.message ? 'noauth'), identity.id
                                    
                                    fn (err ? new Error 'unauthorized')
                            
                                else	
                                    @logger.debug 'delegate authenticate to: %s for: %s', auth.ID, identity.id
                                    auth.authenticate identity, fn
            
                        ##
                        login: (token, user, pass, fn)=>							
                            #console.log 'using manager for login', user
                            
                            _auth (err, auth)=>
                                return fn(err) if err
                                
                                #console.log 'delegate login', token
                            
                                auth.login token, user, pass, (err)=>
                                    
                                    #console.log 'login granted', _user, @id
                                    
                                    fn err
                            
                            
                        ##
                        logout: (token, fn)=>
                                
                            #console.log 'using manager for logout'
                            _auth (err, auth)=>
                                return fn(err) if err
                                
                                #console.log 'delegate logout', token
                                auth.logout  token, (err)=>

                                    __user = null
                                
                                    fn? err
                        
                ##		
                if config.TOKEN
                    @_getAuthManager().authorize config.TOKEN

                    
            return config 
                                
                
        
        ##
        ##
        ##
        _permitAccess: (identity, key, args, fn)->
            super identity, key, args, (err)=>
                
                checks = [

                    (next)=> ## check for general remote restriction
                        
                        next (@data.permissions?[key] || @data.permissions) isnt false
                        
                ,

                    (next)=> ## check for user restriction and test identity.login
                        
                        if user = (@data.permissions?[key]?.user || @data.permissions?.user)
                            identity.login (err, login)=>
                                next login && login.match user
                        
                        else
                            next true
                ,

                    (next)=> ## check for roles restriction and test identity.hasRole
                        if roles = (@data.permissions?[key]?.roles || @data.permissions?.roles)
                            identity.hasRole roles, (err, ok)=>
                                next ok
                                
                        else
                            next true
                
                    
                ]
                
                permit = (ok)=>
                    return fn(new floyd.error.Forbidden @ID+'.'+key) if !ok
                    
                    if check = checks.shift()
                        check permit
                    
                    else fn()
                
                ## start recursion
                permit true

        ##
        ##
        ##
        _init: (level, status, done)->
            __first = false
                        
            ##
            @_process @children,
            
                ##
                each: (child, next)->			
                    if child[level]
                        child[level] next
                            
                    else next()

                ##				
                done: (err)=>
                    
                    if !__first && ( __first = true )
                        @_changeStatus status
                        
                    done err
                    
                    

        ##
        ##  TODO bootup procedure documentation
        ##
        ## * instanciates its children recursively
        ## * emits booting and booted
        ##
        boot: (done)->			

            @_init 'boot', 'booted', done
                        
                        
        ##
        ## TODO startup procedure documentation
        ##
        ## * starts its children recursively
        ## * emits started and running
        ##
        start: (done)->

            @_changeStatus 'started'
            
            @_init 'start', 'running', done
                                    
                    
                
        ##
        ## TODO stop procedure documentation
        ##
        ## * stops its children recursively
        ## * emits shutdown and stopped
        ##
        stop: (done)->
            
            @_changeStatus 'shutdown'
            
            @_init 'stop', 'stopped', done

        
        
        ##
        ## TODO description
        ## 
        ##
        lookup: (name, identity, done)->
                
            __ident = identity.id
            
            _children = 0
            _parent = !!(@parent && @parent.lookup)
            _global = !!(!@parent && floyd.__parent?.lookup)
            
            @logger.debug 'lookup:', name, identity.id
            
            ## --> EXPERIMENTAL identity based lookups cache -> nero
            if false
                if !(lookups = LOOKUPS[__ident])
                    #@logger.info 'create lookups cache for', __ident
                    
                    lookups = LOOKUPS[__ident] = {}
                        
                    identity.on 'destroyed', ()=>
                        @logger.info 'destroy lookups cache for', __ident
                        delete LOOKUPS[__ident]
                    
                    
                        
                        
                ## interrupt search here and return lookup from cache
                if lookups[name]
                    @logger.debug 'found cached:', name, identity.id
                    return done(null, lookups[name]) 
                
            ## <-- EXPERIMENTAL
            
            
            @logger.debug 'start search', name, identity.id
            
            n=0
            
            found = false
            
            __found = ()=>
                found = true
            
            __check = ()=>
                return found
                
            _try = (err, ctx)=>
                #@logger.debug found, '_try', ctx?.ID, identity.id
                
                if !__check()
                
                    if ctx
                    
                        ## EXPERIMENTAL identity based lookups cache -> nero
                        if false
                            if !lookups[name]
                                #@logger.info 'add %s to cache for', name, __ident
                            
                                lookups[name] = ctx
                             
                        __found()
                        
                        #@logger.debug __check(), n++, 'found', ctx.ID, identity.id
                        done null, ctx
                    
                    else if !err
                        #console.log 'next'
                        next()
                        
                    else
                        done err
                
                else console.warn 'double found for lookup:', name, identity.id
            
            
            ##
            ## recursive function calls it's self until a notfound error is thrown
            next = ()=>
                
                if !__check()
                    
                    ##
                    ## search children
                    ##
                    if child = @children[_children++]
                        id = child.id
                        
                        if !__check()
                            @logger.debug 'test child', id
                            
                            ## 1. the requested context is a direct child. 
                            if name is id 
                                
                                @logger.debug 'found as a direct child', child.id
                                
                                #console.log @ID, name
                                child.forIdentity identity, _try
                            
                            ## 2. the prefix of name matches child.id
                            else if name.substr(0, id.length) is id
                                
                                @logger.debug 'searching for %s in %s', name.substr(id.length+1), child.ID
        
                                child.lookup name.substr(id.length+1), identity, _try
                            
                            else								
                                next()
                        
                    ##
                    ## self lookup
                    ##						
                    else if name is @id
                        
                        ## 4. last but not least it happens that 
                        ## someone asks us about our self... 
                        
                        @logger.debug 'its my self', name, @ID
    
                        @forIdentity identity, _try
                    
                    
                    ##
                    ##
                    ##
                    else if name.substr(0, @id.length) is @id
                    
                        @lookup name.substr(@id.length + 1), identity, _try
                    
    
                    ##
                    ## search parent
                    ##
                    else if _parent
                        _parent = false
                        
                        ## 3. if we still did not found anything we
                        ## delegate that to the parent
                        
                        @logger.debug 'delegate to parent', @parent.ID, name
                        
                        process.nextTick ()=>					
                            @parent.lookup name, identity, _try
                    
                    
                    ##
                    ## global parent
                    ##
                    else if _global 
                        _global = false
                    
                        ## 5. EXPERIMENTAL 
                        
                        @logger.debug 'maybe its global', @ID, name, floyd.__parent
                    
                        floyd.__parent.lookup name, identity, _try
                    
                    
                    ##
                    ## not found
                    ##
                    else
                        
                        err = new Error('Context not found: '+name)
    
                        if done
                            done err
                        else
                            throw err
                
            
            ## start recursion
            next()
        
        
        ##
        ## delegates a method call down the hirarchy
        ## propagates errors if the last value in args is a fn
        ##
        ## returns result object -> check for res.success
        ##
        delegate: (method, args...)->
            
            #@logger.info 'delegation of method', method, args
            
            _parent = @parent
            while _parent && !_parent[method] && _parent._parent
                #@logger.info 'checking parent', _parent.id
                
                _parent = _parent._parent
            
            if _parent && _parent[method]
                #@logger.info 'using parent', _parent.id
                
                try
                    return success: true, result: _parent[method].apply _parent, args
                    
                catch err
                    err.message = 'Delegation error in '+@ID+'\n'+err.message
                    throw err
            
            else
                return success: false

        ##
        ##
        ##
        _process: (obj, {each, done})->
            floyd.tools.objects.process obj, each: each, done: done
        
        
        ##
        ## nice logger id
        ##
        _createLogger: (id)->
            
            type = @type

            logger = new floyd.logger.Logger "#{id} - (#{type})"			
            
            if (level = @data.find 'logger.level')
            
                logger.level(logger.Level[level])
            
            return logger
            
        
        ## 
        ## triggers a status change emits status event
        ##	
        _changeStatus: (status)->
            
            if status
                @_status = status
                
                @_emit 'before:'+@_status
                
                if @logger.isLoggable @logger.Level.STATUS
                    @logger.status 'status changed to', @_status
    
                @_emit @_status
            
                @_emit 'after:'+@_status
            
        
            
        ## EventEmitter 
        
        ##
        ## delegates
        ##
        on: ()->
            @addListener.identity = @on.identity
            @addListener.apply @, arguments					
            return @
        
        off: ()->
            @removeListener.apply @, arguments					
            return @
        
        addListener: (action, handler)->
            @_emitter.addListener.apply @_emitter, arguments							
            if @addListener.identity
                if !handler
                    console.log 'no handler', arguments
                    
                @addListener.identity.on 'destroyed', ()=>
                    @removeListener action, handler
            
            #console.log @ID, @_emitter._events
                
            return @
        
        removeListener: (action)->
            @_emitter.removeListener.apply @_emitter, arguments							
            return @
        
        once: ()->
            @_emitter.once.apply @_emitter, arguments	
            return @
        
        
        ##
        ##
        ##
        _createEmitter: (config)->
            
            @_emitter = new events.EventEmitter()
            
            @_emitter.setMaxListeners @data.events?.listeners ? 5
            
            for action in ACTIONS
                do(action)=>
                    if typeof (handler = @[action]) is 'function'
                        
                        @on action, (event)=>							
                            handler.apply @, [event]
                            
            if config.events
                for action, handler of config.events
                    do(action, handler)=>
                    
                        @on action, (event)=>
                            handler.apply @, [event]
            
            
            return @_emitter
            
            
        ##
        ##
        ##
        _emit: (actions, event, args)->
            
            if typeof actions is 'string'
                actions = [actions]
            
            if typeof (event ?= {}) is 'string'
                event: 
                    topic: event			
            
            event.origin ?=
                type: @type
                id: @id
                ID: @ID
                forIdentity: (identity, fn)=>
                    @forIdentity identity, fn					
            
            #console.log @id+': emitting floyd event:', event, actions
            
            ##
            for action in actions
                event.type = action
                
                @_emitter.emit action, event, args				
                
            return @
        
        
        ##
        ##
        ##
        _message: (msg)->
            
            @logger.info 'message recived:', msg

            @_emit 'message:'+msg.topic

