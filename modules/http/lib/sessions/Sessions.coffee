
events = require 'events'

module.exports =

    ##
    ## 
    ##
    class HttpSessions extends floyd.auth.AuthContext
        
        configure: (config)->
        
            @_hiddenKeys.push 'Registry', 'Session'
            super new floyd.Config
            
                data:
                    cookie:
                        name: 'FSID'
                                        
                    registry:
                        type: 'http.sessions.Registry'
                        interval: 60
                        timeout: 3600
                        
                        sessions:
                            type: 'http.sessions.Session'
                    
            , config	

        ##
        ##
        ##
        boot: (done)->
            
            @_registry = new (floyd.tools.objects.resolve @data.registry.type) @data.registry, @
            
            super done
        
        ##
        ##
        ##
        start: (done)->
            
            exclude = @data.find 'no-session-routes', []
            
            ## use the next HttpContext (idealy our parent) to connect req handler
            @delegate '_addMiddleware', (req, res, next)=>
                return next() if @data.disabled				
                
                for expr in exclude
                    return next() if req.url.match expr
                
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
            
            return fn(new Error 'login failed') if !sess || !user || !pass
            
            users = @parent.children.users
            
            users.get user, (err, data)=>	

                return fn(err || new Error 'login failed') if err || !data
                
                if data.active is false || !floyd.tools.crypto.password.verify pass, data.pass
                    console.warn 'access denied for %s@%s', user, sid
                     
                    fn new Error 'login failed' 
                
                else
                    data.lastlogin = +new Date()
                    
                    @_checkPasswordHash user, pass, data, (err, data)=>
                        return fn(err) if err
                        
                        users.set user, data, (err)=>
                    
                            data = floyd.tools.objects.clone data,	
                                login: user
                        
                            delete data.pass
                        
                            sess.public.user = data
                        
                            ##
                            fn null, data
                    
        
        ##
        ##
        ##
        _checkPasswordHash: (user, pass, data, fn)->
            
            cfg = floyd.tools.crypto.password._options

            parts = data.pass.split '-'
            
            if parts.length is 1 \          ## check for old-style password hash 
            or cfg.hasher isnt parts[1] \   ## check for new hash config
            or cfg.keySize isnt (parseInt parts[2]) \
            or cfg.iterations isnt (parseInt parts[3])
                
                data.pass = floyd.tools.crypto.password.create pass
            
                console.warn 'replacing password hash', data.pass
                
                
            ##
            fn null, data
        
        ##
        ##
        ##
        logout: (token, fn)->
            
            sid = token.substr 40 ## TODO - validate token
            
            #console.log 'logout %s@%s', user, sid
            
            if (sess = @_registry.get(sid))
                
                delete sess.public.user
                
                
            fn()
                
        
        ##
        ## 
        ##
        authorize: (token, fn)->            				
            
            if token && (sess = @_registry?.get (sid = token.substr 40))
                
                #console.log 'found session', sess, sess.public.user?.login

                ## initialize destroy hook on the fly
                if !sess.destroyHook
                    sess.on 'destroy', ()=>
                        sess.destroyHook new Error 'session destroyed'
                
                ## register the current callback as the destroy hook
                sess.destroyHook = fn
                        
                ## authorize loggedin session
                if user = sess.public.user?.login
                       
                    @parent.children.users.get user, (err, data)=>
                        return fn(err) if err
                        
                        data = floyd.tools.objects.clone data,  
                            login: user
                            
                        delete data.pass
                            
                        fn null, sess.public.user = data
                
                ## authorize anonymous session        
                else
                    fn()
                    
            
            else 
                super token, fn
                
        ##
        ##
        ##
        authenticate: (identity, fn)->
            
            @logger.debug 'session authenticate identity %s', identity.id
            
            super identity, (err)=>
                return fn() if !err ## successfully authenticated
                
                identity.token (err, token)=>
                    if err || !token
                        @logger.warning 'session authenticate NO TOKEN', identity.id

                        return fn(err || new Error 'session authenticate NO TOKEN') 
                
                    sid = token.substr 40				
                    
                    @logger.fine 'session authenticate session %s', sid

                    @_load sid, (err, sess)=>
                        return fn(err) if err
                    
                        @logger.finer 'session authenticate hash %s', token.substr 0, 39
                    
                        if token is sess.token
                        
                            @logger.debug 'session authenticate SUCCESS', identity.id 
                        
                            fn()
                        
                        else
                            @logger.debug 'session authenticate FAILURE', identity.id 
                        
                            fn new Error 'session authenticate FAILURE'
                            
        
        
        ##
        ##
        ##
        _load: (sid, fn)->
            
            #console.log 'load session', sid
            
            ## search and create
            if !(sess = @_registry.get sid)
            
                @_registry.add sess = new (floyd.tools.objects.resolve @data.registry.sessions.type) sid, @data.registry.sessions
                
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
        _createSID: ()->
            @_registry.createSID()
            
        
     