
events = require 'events'

module.exports =

    ##
    ## 
    ##
    class HttpSessions extends floyd.Context
        
        constructor: (config, parent)->
            super config, parent
            @_hiddenKeys.push 'Registry', 'Session'
        
        configure: (config)->
            @_TOKENS = config.tokens
            super new floyd.Config
            
                data:
                    cookie:
                        name: 'FSID'
                                        
                    registry:
                        interval: 60
                        timeout: 600
                    
            , config	
        
        ##
        ##
        ##
        start: (done)->

            ## TODO: read persisted
            @_registry = new @Registry @data.registry
            
                        
            ## use the next HttpContext (idealy our parent) to connect req handler
            @delegate '_addMiddleware', (req, res, next)=>
                return next() if @data.disabled				
                
                @_load @_getSID(req), (err, sess)=>
                    return next(err) if err
                        
                    #console.log 'session', sess.public
                    
                    req.session = sess.public
                    
                    _end = res.end
                    res.end = (args)=>
                        @_release req, sess, (err)=>							
                            return next(err) if err
                                            
                            req.session = null 		## <-- remove references to avoid memory leaks
                            
                            _end.apply res, args
                                
                    ##	
                    next()
                    
            
            ##
            super done
        
        
        ##
        ## BLOCKER: review and apply some common security strategies
        ##
        _getSID: (req)->
            
            #console.log 'search cookie', @data.cookie.name, req.url, req.headers.cookie
            
            if !(sid = req.cookies.get @data.cookie.name)

                sid = @_createSID()
                
                #console.log 'create cookie', sid				
                
                req.cookies.set @data.cookie.name, sid
            
            #console.log 'sid', sid
            
            ##
            return sid
        
        
        ##
        ##
        ##
        createSession: (fn)->
            console.log 'creating session'
            
            fn null, @_load @_createSID(), fn
        
        ##
        ##
        ##
        login: (token, user, pass, _fn)->
            
            fn = (err, user)=>
                if err
                    setTimeout ()=>
                        _fn err
                    , 2500
                    
                else _fn null, user
            
            sid = token.substr 40 ## TODO - validate token
        
            sess = @_registry.get(sid)
            
            _dbq = false
            
            _dbq && console.log 'login %s@%s pass:', user, sid, !!pass
            
            return fn(new Error 'login failed') if !sess || !user || !pass
            
            users = @parent.children.users
            
            users.get user, (err, data)=>	

                return fn(err || new Error 'login failed') if err || !data
                
                hash = floyd.tools.crypto.password pass, data?.pass.substr(40)	
                
                _dbq && console.log 'check', hash is data?.pass
                
                if data.pass isnt hash
                    console.warn 'access denied for %s@%s', user, sid
                     
                    fn new Error 'login failed' 
                
                else
                    _dbq && console.log 'access granted %s@%s', user, sid 
                    
                    data.lastlogin = +new Date()
                    
                    users.set user, data, (err)=>
                    
                        sess.public.user =	floyd.tools.objects.clone data,	
                            login: user
                        
                        delete sess.public.user.pass
    
                        ##
                        fn null, sess.public.user
                    

        ##
        ##
        ##
        logout: (token, fn)->
            
            sid = token.substr 40 ## TODO - validate token
            
            #console.log 'logout %s@%s', user, sid
            
            if (sess = @_registry.get(sid))
                
                sess.public.user = floyd.tools.objects.unlink sess.public.user
                
                
            fn()
                
        
        ##
        ## 
        ##
        authorize: (token, fn)->
            
            sid = token.substr 40				
            
            #console.log 'session authorize session %s', sid
            
            if (sess = @_registry.get sid)
                
                fn null, sess.public.user

            else 
                #console.warn 'user failure', identity.id, sess, sess?.user
                
                fn new Error 'unauthorized'
                
        ##
        ##
        ##
        authenticate: (identity, fn)->
            
            @logger.debug 'session authenticate identity %s', identity.id
            
            identity.token (err, token)=>
                if err || !token
                    @logger.debug 'session authenticate NO TOKEN', identity.id
                     
                    return fn(err || new Error 'unauthorized') 
                
                ##
                if @_TOKENS && @_TOKENS[identity.id.split('.').shift()] is token
                
                    @logger.debug 'found known Token, authenticate SUCCESS', identity.id 
                        
                    fn()
                
                else
                    sid = token.substr 40				
                    
                    @logger.debug 'session authenticate session %s', sid
    
                    @_load sid, (err, sess)=>
                        return fn(err) if err
                        
                        @logger.debug 'session authenticate hash %s', token.substr 0, 39
                        
                        if token is sess.token
                            
                            @logger.debug 'session authenticate SUCCESS', identity.id 
                            
                            fn()
                            
                        else
                            @logger.debug 'session authenticate FAILURE', identity.id 
                            
                            fn new Error 'unauthorized'
                            
        
        
        ##
        ##
        ##
        _load: (sid, fn)->
            
            #console.log 'load session', sid
            
            ## search and create
            if !(sess = @_registry.get sid)
            
                @_registry.add sess = new Session sid
                
            sess.resume()			
            
            ## deliver
            fn null, sess
            
            
        ##
        ##
        ##
        _release: (req, sess, fn)->

            sess.suspend()
            
            fn()
        
        
        ##
        ##
        ##
        _createSID: ()->
        
            floyd.tools.strings.uuid()
        
        
        ##
        ##
        ##
        Registry: (config)->
            pool = {}
            _running = false
            
            observe = ()->
                
                _running = setInterval ()=>
                    
                    if !(keys = floyd.tools.objects.keys pool).length
                        clearInterval _running
                        _running = null
                    
                    else
                    
                        now = +new Date()
                        
                        #console.log 'starting cleanup run:', now, keys
                        
                        for sid in keys
                            do (sid)=>
                                sess = pool[sid]
                                
                                #console.log 'check session', (sess.touched + config.timeout * 1000) < now, sess
                                        
                                if (sess.touched + config.timeout * 1000) < now
                                    sess.destroy()
                                    delete pool[sid]
                    
                , config.interval * 1000
            
            
            ## public api
            
            ##	
            add: (sess)->
            
                pool[sess.SID] = sess
                
                observe() if !_running
            
                
            ##
            get: (id)->
            
                pool[id]
            
            
        
        
        ##
        ##
        ##		
        Session:
        
            class Session extends events.EventEmitter
            
                constructor: (@SID)->
                
                    #console.log 'create session', @SID
                    
                    @token = floyd.tools.crypto.hash(floyd.tools.strings.uuid()+@SID)+@SID
                     
                    @public =
                        TOKEN: @token
                        on: ()=> @addListener.apply @, agruments
                        off: ()=> @removeListener.apply @, agruments
                        once: (action, handler)=> 
                            @on action, _handler = (event)=>
                                @off _handler
                                handler event
                                
                                
                
                ##
                touch: ()->
                    @touched = @public.touched = +new Date()
                    
                    #console.log 'touch session', @SID

                    @emit 'touch', @touched 
                    
                
                ##
                destroy: ()->
                
                    #console.log 'destroy session', @SID
                    
                    @emit 'destroy'
                
                
                ##
                suspend: ()->
                
                    #console.log 'suspend session', @SID
                    
                    @touch()
                    
                    @emit 'suspend'
         
         
                ##
                resume: ()->
                
                    #console.log 'resume session', @SID

                    @emit 'resume'
        