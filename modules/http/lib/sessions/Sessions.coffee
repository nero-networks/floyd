
events = require 'events'

module.exports =

    ##
    ##
    ##
    class SessionsManager extends floyd.auth.AuthContext

        configure: (config)->
            super new floyd.Config
                data:
                    cookie:
                        name: 'FSID'

                    login:
                        id: 'id'
                        pass: 'pass'

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
            super done

            exclude = @data.find 'no-session-routes', []

            ## use the next HttpContext (idealy our parent) to connect req handler
            @delegate '_addMiddleware', (req, res, next)=>
                #console.log 'sessions init'
                if @data.disabled
                    @logger.warning 'DEPRECATED: use data.cookie = false'
                return next() if @data.disabled || @data.cookie is false

                for expr in exclude
                    return next() if req.url.match expr

                #console.log 'sessions getSID'
                @_getSID req, (err, SID)=>
                    return next(err) if err
                    #console.log 'sessions', SID
                    @_load SID, (err, sess)=>
                        #console.log 'sessions', sess, err
                        return next(err) if err

                        #console.log 'session', sess.public

                        req.session = res.session = sess.public

                        floyd.tools.objects.intercept res, 'end', (args..., end)=>
                            end.apply res, args

                            req.session = res.session = null

                        ##
                        next()



        ##
        ##
        ##
        _getSID: (req, fn)->

            #console.log 'search cookie', @data.cookie.name, req.url, req.headers.cookie

            if SID = req.cookies.get @data.cookie.name
                fn null, SID

            else
                #console.log 'create SID'
                @_registry.createSID (err, SID)=>

                    #console.log 'create cookie', SID

                    req.cookies.set @data.cookie.name, SID

                    fn null, SID

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

            return fn(new floyd.error.Unauthorized 'login') if !sess || !user || !pass

            @_loadUser user, (err, data)=>

                return fn(err || new floyd.error.Unauthorized 'login') if err || !data

                if data.active is false || !floyd.tools.crypto.password.verify pass, data[@data.login.pass]
                    @logger.warning 'access denied for %s@%s', user, sid

                    fn new floyd.error.Unauthorized 'login'

                else
                    data.lastlogin = +new Date()

                    @_checkPasswordHash user, pass, data, (err, data)=>
                        return fn(err) if err

                        @parent.children.users.set data.id, data, (err)=>

                            data = floyd.tools.objects.clone data,
                                login: user

                            delete data[@data.login.pass]

                            sess.public.user = data

                            ##
                            fn null, data

        ##
        ##
        ##
        _loadUser: (id, fn)->
            query = {}
            query[@data.login.id] = id

            @parent.children.users.find query,
                limit: 1
            , null, (err, items)=>
                fn err, items?[0]


        ##
        ##
        ##
        _checkPasswordHash: (user, pass, data, fn)->

            cfg = floyd.tools.objects.extend floyd.config.crypto.password, @data.password

            parts = data[@data.login.pass].split '-'

            if parts.length is 1 \          ## check for old-style password hash
            or cfg.hasher isnt parts[1] \   ## check for new hash config
            or cfg.keySize isnt (parseInt parts[2]) \
            or cfg.iterations isnt (parseInt parts[3])

                data[@data.login.pass] = floyd.tools.crypto.password.create pass

                @logger.warning 'replacing password hash', data[@data.login.pass]


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
                sess.destroyHook = fn

                sess.on 'destroy', ()=>
                    sess.destroyHook new Error 'session destroyed'

                ## authorize loggedin session
                if user = sess.public.user?.login

                    @_loadUser user, (err, data)=>
                        return fn(err) if err

                        data = floyd.tools.objects.clone data,
                            login: user

                        delete data[@data.login.pass]

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

            @logger.finer 'session authenticate identity %s', identity.id

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

                            @logger.fine 'session authenticate SUCCESS', identity.id

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

            sess.touch()

            ## deliver
            fn null, sess


        ##
        ##
        ##
        createSID: (fn)->
            @logger.warning 'pubic createSID is deprecated and will be removed in future'
            @_registry.createSID fn
