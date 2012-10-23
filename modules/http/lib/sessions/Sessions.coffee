
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
            
            @_registry = new (floyd.tools.objects.resolve @data.registry.type) @data.registry
            
            super done
        
        ##
        ##
        ##
        start: (done)->
                        
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
                    
                        data = floyd.tools.objects.clone data,	
                            login: user
                        
                        delete data.pass
                        
                        sess.public.user = data
                        
                        ##
                        fn null, data
                    

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
                
                #console.log 'found session', sess, sess.public.user?.login
                
                if user = sess.public.user?.login
                                        
                    @parent.children.users.get user, (err, data)=>
                        return fn(err) if err
                        
                        data = floyd.tools.objects.clone data,  
                            login: user
                            
                        delete data.pass
                            
                        fn null, sess.public.user = data
                        
                else
                    fn new Error 'not logged in'
                    

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
        _createSID: ()->
        
            floyd.tools.strings.uuid()
        
     