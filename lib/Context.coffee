
events = require 'events'

ACTIONS = ['configured', 'booted', 'started', 'running', 'shutdown', 'stopped']

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
        constructor: (@parent)->
            super null, @parent
            
            @_status = []
        
            @_hiddenKeys.push 'data', 'parent', 'children', 'permissions', 'lookup', 'configure', 'init', 'boot', 'booting', 'booted', 'start', 'started', 'running', 'shutdown', 'stop', 'stopped', 'error', 'delegate'
            
        
        ##
        ##
        ##
        init: (config={}, done)->         
            
            config = @configure config
            
            @id = config.id
                    
            @ID = if !(@parent?.ID) then @id else @parent.ID+'.'+@id
            
            if typeof (@type = config.type) is 'function'
                @type = @ID+'.'+(@type.name || 'DynContext')
            
            @data = new floyd.data.SearchableMap config.data, @parent?.data

            @logger = @_createLogger @ID
            
            if @data.permissions
                @logger.warning '@data.permissions is deprecated use config.permissions instead'
                config.permissions = @data.permissions
            
            @permissions = config.permissions
            
            @identity = @_createIdentity()

            @_emitter = @_createEmitter config
            
            @children = new floyd.data.MappedCollection()

            @_changeStatus 'configured'
            
            process.nextTick ()=>
                @_process config.children,
                    
                    each: (child, next)=>
                        
                        @_createChild child, next
                            
                    done: done

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
                ctx = new ctor @
                
                ctx.init config, (err)=>
                    return done(err) if err
                    @children.push ctx
                
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
                    @logger.warning 'context not stopped!'
                
                @_init 'destroy', null, (err)=>
                    done?(err) if err
                    
                    if !destroy
                        done?()
                    
                    else
                    
                        destroy (err)=>
                        
                            @_changeStatus 'destroyed'
                            
                            done? err
            
            ##
            ##
            if manager = config.data.authManager
                
                #console.log 'prepare _createAuthHandler', manager
                
                if config.TOKEN
                    floyd.tools.objects.intercept @, 'boot', (done, boot)=>
                        
                        first = true
                        @_getAuthManager().authorize config.TOKEN, (err)=>
                            #return done(err) if err
                            
                            if first 
                                first = false
                                boot done
                
                ##
                @_createAuthHandler = ()=>
                    
                    #console.log '_createAuthHandler', manager
                    
                    _auth = (fn)=>
                        # EXPERIMENTAL shortcut. use child if found
                        # re-think implications of unprotected usage
                         
                        if (ctx = @children[manager]) 
                            fn null, ctx
                        
                        else 
                            @lookup manager, @identity, (err, ctx)=>
                                if !ctx && config.ORIGIN
                                    @lookup config.ORIGIN+'.'+manager, @identity, fn
                                
                                else
                                    fn err, ctx
                    
                    new floyd.auth.Handler

                        ##
                        authorize: (token, fn)=>
                            _auth (err, auth)=>
                                return fn(err) if err
                                auth.authorize token, fn
                            
                        ##
                        authenticate: (identity, fn)=>
                            _auth (err, auth)=>
                                return fn(err) if err
                                auth.authenticate identity, fn
            
                        ##
                        login: (token, user, pass, fn)=>
                            _auth (err, auth)=>
                                return fn(err) if err
                                auth.login token, user, pass, fn
                            
                            
                        ##
                        logout: (token, fn)=>
                            _auth (err, auth)=>
                                return fn(err) if err
                                auth.logout token, fn
                        
                    
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
            super identity, key, args, (err, permitted)=>
                return fn(err) if err
                
                checks = [
                    (next)=>
                        next permitted
                        
                ,
                    (next)=>
                        if @permissions?.__checks
                            for check in @permissions.__checks
                                do(check)=>
                                    checks.push (next)=>
                                        check.apply @, [identity, key, args, next]
                
                        
                        next true
                        
                ,

                    (next)=> # check for general remote restriction
                        
                        next (@permissions?[key] || @permissions) isnt false
                        
                ,
                
                    (next)=> # custom check function - must callback true to permit!
                        if typeof (check = @permissions) is 'function' || typeof (check = @permissions?[key]) is 'function' || check = (@permissions?[key]?.check || @permissions?.check)
                            
                            check identity, key, args, next                            
                            
                        else next true
                    
                ,

                    (next)=> # check for identity.id restriction
                        
                        if id = (@permissions?[key]?.identity || @permissions?.identity)
                            next identity.id is id
                        
                        else next true
                ,

                    (next)=> # check for token restriction
                        
                        if token = (@permissions?[key]?.token || @permissions?.token)
                            
                            identity.token (err, _token)=>
                                next token is _token
                        
                        else next true
                ,

                    (next)=> # check for login restriction
                        
                        if (@permissions?[key]?.login || @permissions?.login)
                            
                            identity.login (err, login)=>
                                next !!login
                        
                        else next true
                ,

                     (next)=> # check for user restriction and test identity.login
                        
                        if user = (@permissions?[key]?.user || @permissions?.user)
                            
                            identity.login (err, login)=>
                                next login is user
                        
                        else next true
                ,

                    (next)=> # check for roles restriction and test identity.hasRole
                        if roles = (@permissions?[key]?.roles || @permissions?.roles)
                            
                            identity.hasRole roles, (err, ok)=>
                                next ok
                                
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
                        if level is 'stop' || level is 'destroy'
                            child[level] next
                        
                        else process.nextTick ()->
                            child[level] next
                            
                    else next()

                ##
                done: (err)=>
                    
                    if !__first && ( __first = true )
                        if level is 'stop' || level is 'destroy'
                            @_changeStatus? status
                            done?()
                        
                        else
                            done?()
                            @_changeStatus? status
                                            
                    else if err
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
        ##
        ##
        lookup: (name, identity, done)->
            if !identity || !identity.id || !identity.token
                return done new Error '2. parameter is not identity'
            
            ## myself
            if name is @id
                @logger.debug 'found(%s) for %s', @ID, identity.id
                return @forIdentity identity, done
            
            ## children
            if (base = name.split('.').shift()) is @id
                base = (name = name.substr base.length + 1).split('.').shift()
            
            for child in @children 
                if child.id is base
                    @logger.debug 'delegate lookup(%s) to child %s for %s', name, child.ID, identity.id
                    return child.lookup name, identity, done
            
            ## parent
            if @parent?.lookup
                @logger.debug 'delegate lookup(%s) to parent %s for %s', name, @parent.ID, identity.id
                return @parent.lookup name, identity, done
            
            ## global
            if floyd.__parent?.lookup
                @logger.debug 'delegate lookup(%s) to global parent for %s', name, identity.id
                return floyd.__parent.lookup name, identity, done
            
            ## not found
            @logger.debug 'lookup(%s) failed for %s', name, identity.id
            done new Error 'Context not found: '+name
            
        
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
            @removeListener.identity = @off.identity
            @removeListener.apply @, arguments
        
        addListener: (action, handler)->
            if !handler
                return console.log 'no handler', action

            @_emitter.addListener action, handler

            if identity = @addListener.identity
                    
                if !(@_eventHandlers ?= {})[identity.id]
                    @_eventHandlers[identity.id] = {}

                    identity.on 'destroyed', ()=>
                        if @_eventHandlers[identity.id]
                            for action, handler of @_eventHandlers[identity.id]
                                @removeListener action, handler
                            delete @_eventHandlers[identity.id]

                @_eventHandlers[identity.id][action] = handler
        
        removeListener: (action, handler)->
            if identity = @removeListener.identity

                if @_eventHandlers[identity.id]?[action]
                    handler = @_eventHandlers[identity.id][action]
                    
                    delete @_eventHandlers[identity.id][action]

            @_emitter.removeListener action handler
        
        once: (action, handler)->            
            @_emitter.once action, handler
        
        
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
                event = 
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
                if !stop && ACTIONS.indexOf(action) is -1 && (@data.events?.delegate is true || @data.events?.delegate?.indexOf(action) > -1)
                    
                    @parent._emit action, event, args
                
            return @
        
        
