
events = require 'events'

ACTIONS = ['configured', 'booted', 'started', 'running', 'shutdown', 'stopped', 'message']

USELOOKUPSCACHE = false
LOOKUPSCACHE = {}

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
            @_status = []
            
            config = @configure config

            @id = config.id
                    
            @ID = if !(@parent?.ID) then @id else @parent.ID+'.'+@id
            
            if typeof (@type = config.type) is 'function'
                @type = @ID+'.'+(@type.name || 'DynContext')					
            
            @data = new floyd.data.SearchableMap config.data, @parent?.data
            
            super @ID, @parent
            
            @_emitter = @_createEmitter config
            
            @_hiddenKeys.push 'configure', 'boot', 'booting', 'booted', 'start', 'started', 'running', 'shutdown', 'stop', 'stopped', 'error', 'delegate', 'data', 'parent', 'children'
            
            @children = new floyd.data.MappedCollection()

            @_changeStatus 'configured'

            @_process config.children,
                
                each: (child, next)=>
                    
                    @_createChild child, next			
                        
                done: (err)=>
                    @error(err) if err				

        ##
        ##
        ##
        error: (err)=>
            if !@_errorHandler
                if @parent
                    @parent.error err
                
                else
                    @logger.error err
                
            else
                @_errorHandler err
        
        ##
        ##
        ##
        _createChild: (config, done)->
            if typeof (ctor = config.type) isnt 'function'
                ctor = floyd.tools.objects.resolve(ctor || 'floyd.Context')
            
            done ?= (err)=> @error(err) if err
                
            if ctor 
                @children.push ctx = new ctor config, @

                if @_status.indexOf('booting') != -1
                    
                    ctx.boot (err)=>
                        return done(err) if err
                        
                        if @_status.indexOf('started') != -1                            
                            ctx.start (err)=>
                                done err, ctx
                            
                        else
                            done null, ctx
                    
                else
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
            
            if hostconfig = config.hostconfig?[floyd.system.hostname]

                if typeof hostconfig is 'function'
                    hostconfig.apply @, [config]
                else
                    floyd.tools.objects.extend config, hostconfig
            
            config = new floyd.Config config
            
            # extend context with methods from config. add @method._super for each
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
                                    
            
            ##
            ##           
            floyd.tools.objects.intercept @, 'destroy', (done, destroy)=>
            
                if @stop && @_status.indexOf('stopped') is -1
                    return @logger.warning 'context not stopped!'
                
                @_init 'destroy', null, (err)=>
                    done?(err) if err					
                    
                    if !destroy
                        done?()
                    
                    else
                    
                        destroy (err)=>
                        
                            @_changeStatus 'destroyed'	
                            
                            done? err
            
            if manager = config.data.authManager
                
                if config.ORIGIN
                    manager = config.ORIGIN+'.'+manager
                
                #console.log 'prepare _createAuthHandler', manager
                
                __user = config.USER
                
                ##
                @_createAuthHandler = ()=>
                    
                    #console.log '_createAuthHandler', manager, __user
                    
                    _auth = (fn)=>
                        # EXPERIMENTAL shortcut. use child if found
                        # re-think implications of unprotected usage
                         
                        if (ctx = @children[manager]) 
                            fn null, ctx
                        
                        else 
                            @lookup manager, @identity, fn
                    
                    new floyd.auth.Handler

                        #
                        authorize: (token, fn)=>
                            
                            #console.log 'autorizazion request', __user, @id
                            
                            if !@identity
                                #console.log 'no identity', __user?.login
                                
                                fn null, __user

                            else
                                #console.log 'using manager for authorize'
                                _auth (err, auth)=>
                                    return fn(err) if err

                                    #console.log 'delegate authorize', @identity.id
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

                    
            if typeof config?.configure is 'function'
                config = config.configure.apply @, [config]
            
            ##
            
            if config.data?.dump
                console.log floyd.tools.objects.dump config
            
            return config 
                                
                
        
        ##
        ##
        ##
        _permitAccess: (identity, key, args, fn)->
            super identity, key, args, (err)=>
                
                checks = [
                    (next)=>
                        if @data.permissions?.__checks
                            for check in @data.permissions.__checks
                                do(check)=>
                                    checks.push (next)=>
                                        check.apply @, [identity, key, args, next]
                
                        
                        next true
                        
                ,

                    (next)=> # check for general remote restriction
                        
                        next (@data.permissions?[key] || @data.permissions) isnt false
                        
                ,

                    (next)=> # check for login restriction
                        
                        if (@data.permissions?[key]?.login || @data.permissions?.login)
                            
                            identity.login (err, login)=>
                                next !!login
                        
                        else next true
                ,

                     (next)=> # check for user restriction and test identity.login
                        
                        if user = (@data.permissions?[key]?.user || @data.permissions?.user)
                            
                            identity.login (err, login)=>
                                next login is user
                        
                        else next true
                ,

                    (next)=> # check for roles restriction and test identity.hasRole
                        if roles = (@data.permissions?[key]?.roles || @data.permissions?.roles)
                            
                            identity.hasRole roles, (err, ok)=>
                                next ok
                                
                        else next true
                
                ,
                
                    (next)=> # custom check function - must callback true to permit!
                        if typeof (check = @data.permissions) is 'function' || typeof (check = @data.permissions?[key]) is 'function' || check = (@data.permissions?[key]?.check || @data.permissions?.check)
                            
                            check identity, key, args, next                            
                            
                        else next true
                    
                ]
                
                permit = (ok)=>
                    return fn(new floyd.error.Forbidden @ID+'.'+key) if !ok
                    
                    if check = checks.shift()
                        check permit
                    
                    else fn()
                
                # start recursion
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
                        @_changeStatus? status
                        
                    done? err
                    
                    

        ##
        ##  TODO bootup procedure documentation
        ##
        ## * instanciates its children recursively
        ## * emits booting and booted
        ##
        boot: (done)->			
            @_errorHandler = (err)=>
                done(err) if err
            
            @_changeStatus 'booting'
            
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
            
            if !(__ident = identity.id) || !identity.token
                console.log '2. parameter is not identity', @ID
                throw new Error '2. parameter is not identity'
            
            _children = 0
            _parent = !!(@parent && @parent.lookup)
            _global = !!(!@parent && floyd.__parent?.lookup)
            
            @logger.debug 'lookup:', name, identity.id
            
            # --> EXPERIMENTAL identity based lookups cache -> nero
            
            if USELOOKUPSCACHE # inactive if false here
                if !(lookupscache = LOOKUPSCACHE[__ident])
                    @logger.info 'create lookups cache for', __ident
                    
                    lookupscache = LOOKUPSCACHE[__ident] = {}
                        
                    identity.on 'destroyed', ()=>
                        @logger.info 'destroy lookups cache for', __ident
                        delete LOOKUPSCACHE[__ident]
                    
                    
                        
                        
                ## interrupt search here and return lookup from cache
                if lookupscache[name]
                    @logger.debug 'found cached:', name, identity.id
                    return done(null, lookupscache[name]) 
                
            # <-- EXPERIMENTAL
            
            
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
                    
                        # --> EXPERIMENTAL identity based lookups cache -> nero
                        
                        if USELOOKUPSCACHE # inactive if false here
                            if !lookupscache[name]
                                @logger.info 'add %s to cache for', name, __ident
                            
                                lookupscache[name] = ctx
                        
                        # <-- EXERIMENTAL
                        
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
                            
                            # 1. the requested context is a direct child. 
                            if name is id 
                                
                                @logger.debug 'found as a direct child', child.id
                                
                                #console.log @ID, name
                                child.forIdentity identity, _try
                            
                            # 2. the prefix of name matches child.id
                            else if name.substr(0, id.length) is id
                                
                                @logger.debug 'searching for %s in %s', name.substr(id.length+1), child.ID
        
                                child.lookup name.substr(id.length+1), identity, _try
                            
                            else								
                                next()
                        
                    ##
                    ## self lookup
                    ##						
                    else if name is @id
                        
                        # 4. last but not least it happens that 
                        # someone asks us about our self... 
                        
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
                        
                        # 3. if we still did not found anything we
                        # delegate that to the parent
                        
                        @logger.debug 'delegate to parent', @parent.ID, name
                        
                        process.nextTick ()=>					
                            @parent.lookup name, identity, _try
                    
                    
                    ##
                    ## global parent
                    ##
                    else if _global 
                        _global = false
                    
                        # 5. EXPERIMENTAL 
                        
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
            while _parent && !_parent[method] && _parent.parent
                #@logger.info 'checking parent', _parent.id
                
                _parent = _parent.parent
            
            if _parent && _parent[method]
                #@logger.info 'using parent', _parent.id
                
                try
                    return success: true, result: _parent[method].apply _parent, args
                    
                catch err
                    err.message = 'Delegation error in '+@ID+'\n'+err.message
                    throw err
            
            else
                #@logger.info 'missed', method
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
                @_status.push status
                
                @_emit 'before:'+status
                
                if @logger.isLoggable @logger.Level.STATUS
                    @logger.status 'status changed to', status
    
                @_emit status
            
                @_emit 'after:'+status
            
        
            
        ## EventEmitter 
        
        ##
        ## delegates
        ##
        on: ()->
            @addListener.identity = @on.identity
            @addListener.apply @, arguments					
        
        off: ()->
            @removeListener.apply @, arguments					
        
        addListener: (action, handler)->
            @_emitter.addListener.apply @_emitter, arguments							
            if @addListener.identity
                if !handler
                    console.log 'no handler', arguments
                    
                @addListener.identity.on 'destroyed', ()=>
                    @removeListener action, handler
            
            #console.log @ID, @_emitter._events
                
        
        removeListener: (action)->
            @_emitter.removeListener.apply @_emitter, arguments							
        
        once: ()->
            @_emitter.once.apply @_emitter, arguments	
        
        
        ##
        ##
        ##
        _createEmitter: (config)->
            
            @_emitter = new events.EventEmitter()
            
            @_emitter.setMaxListeners @data.events?.listeners ? 41 ## shows up in log with 42 ;-)
            
            for action in ACTIONS
                do(action)=>
                    if typeof (handler = @[action]) is 'function'
                        
                        @once action, (event)=>							
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
                
                #console.log 'emit', action, @_emitter
                
                stop = @_emitter.emit action, event, args
                
                ## all non served events are boubled up if @data.events?.delegate is true
                ## or if @data.events?.delegate is an array that contains action as a string
                ## delegation is always suppressed for lifecycle-events        
                if !stop && (@data.events?.delegate is true || @data.events?.delegate?.indexOf action) && ACTIONS.indexOf(action) is -1
                    
                    @parent._emit action, event, args	
                
            return @
        
        
        ##
        ##
        ##
        _message: (msg)->
            
            @logger.info 'message recived:', msg

            @_emit 'message:'+msg.topic

