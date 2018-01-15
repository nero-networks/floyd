
shoe = require('shoe')
dnode = require('dnode')

module.exports =

    class DNodeBridge extends floyd.Context


        ##
        ##
        ##
        configure: (config)->
            @_servers = []

            ##
            ##
            config = super new floyd.Config

                data:
                    parent: false
                    ports: []
                    gateways: []
                    route: '/dnode'

            , config

            if config.data.parent
                config.data.ports.push parent: true

            if !config.data.gateways.length && floyd.system.platform is 'remote'
                config.data.gateways.push 'origin'

            ## hack to connect us before our root-parent gets booted
            _parent = _parent.parent while (_parent ?= @parent || @).parent
            floyd.tools.objects.intercept _parent, 'boot', (done, boot)=>
                @_connect (err)=>
                    return done(err) if err

                    boot (err)=>
                        return done(err) if err

                        @_listen done

            return config

        ##
        ##
        ##
        stop: (done)->
            super (err)=>
                for server in @_servers
                    server.close()
                done err

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
                    if typeof conf is 'string'
                        conf =
                            url: conf

                    if conf.keepalive != false
                        conf.keepalive ?= 1000 * 60 * 5

                    reconn = require('reconnect-core') ()=>
                        c = @_createConnection conf, ()=>
                            @_pipeLocal conf, c, next

                        return c

                    reconn().connect()


        ##
        ##
        ##
        _createConnection: (conf, fn)->
            if conf.url is 'origin'
                @logger.debug 'connecting to origin:', @data.route
                shoe @data.route, fn

            else if conf.tls
                @logger.debug 'connecting to tls-gateway:', conf.host||'localhost', conf.port
                require('tls').connect conf, fn

            else if conf.url
                @logger.debug 'connecting to url:', conf.url
                shoe conf.url, fn
            else
                @logger.debug 'connecting to tcp-gateway:', conf
                require('net').connect conf, fn

        ##
        ##
        ##
        _listen: (fn)->

            @_process @data.ports,

                done: fn

                each: (conf, next)=>
                    if conf.tls
                        @logger.debug 'listening on tls-port:', conf.host||'localhost', conf.port
                    else
                        @logger.debug 'listening on port:', conf

                    handler = (err)=>
                        fn(err) if err

                    if conf.parent

                        parent = @parent
                        while parent && !(server = parent.server) && parent.parent
                            parent = parent.parent

                        @_createServerSocket conf, parent.server, handler

                    else if conf.child

                        @_createServerSocket conf, @children[conf.child], handler

                    else if conf.ctx

                        @lookup conf.ctx, @identity, (err, ctx)=>

                            @_createServerSocket conf, ctx.server, handler

                    else if conf.tls
                        s = require('tls').createServer conf, (c)=>
                            #@logger.info c.getPeerCertificate().subject.CN

                            @_pipeLocal conf, c, handler

                        .listen conf

                        @_servers.push s

                    else
                        s = require('net').createServer (c)=>

                            @_pipeLocal conf, c, handler

                        .listen conf

                        @_servers.push s

                    ##
                    next()
        ##
        ##
        ##
        _pipeLocal: (conf, sock, handler)->
            local = @_createLocal conf, sock, handler

            sock.pipe(local).pipe(sock)

            sock.on 'error', handler
            local.on 'error', handler

        ##
        ##
        ##
        _createServerSocket: (conf, server, handler)->

            sock = shoe (stream)=>
                @_pipeLocal conf, stream, handler

            sock.install server, @data.route



        ##
        ##
        ##
        _createLocal: (conf, sock, fn)->

            ##
            root = @parent || @

            ##
            dnode (proxy, conn)=>

                child = null

                conn.on 'remote', (remote)=>

                    @_authorizeRemote conf, sock, remote, (err)=>
                        if err
                            fn err
                            return sock.end()

                        if !(child = root.children[remote.id])
                            api.remote = child = new floyd.dnode.Remote root

                            child.init (id: remote.id, type:'dnode.Remote'), (err)=>
                                return fn(err) if err

                            child._useProxy conf, remote

                            root.children.push child

                            fn()

                        else
                            child._useProxy conf, remote

                        ##
                        @_emit 'connected',
                            id: remote.id
                            ID: remote.ID

                        ##
                        conn.on 'end', ()=>
                            @_emit 'disconnected',
                                id: remote.id
                                ID: remote.ID


                        ##
                        conn.on 'error', (err)=>

                            console.log 'conn error!', err

                            fn err



                ## remote api
                api = @_createProxy root, conf, sock, proxy, conn

        ##
        ##
        ##
        _createProxy: (root, conf, sock, proxy, conn)->
            api =
                remote: null # to be set after remote is created
                id: root.id
                ID: root.ID

                lookup: (args...)->
                    api.remote.lookup.apply api.remote, args

                token: (fn)->
                    fn null, conf.token

                ping: (fn)->
                    fn() ## pong

                processLogEntry: (args)->
                    root._processLogEntry args


        ##
        ##
        ##
        _authorizeRemote: (conf, sock, remote, fn)->

                checks = [
                    (next)=>
                        if conf.permissions?.__checks
                            for check in conf.permissions.__checks
                                do(check)=>
                                    checks.push (next)=>
                                        check.apply @, [conf, sock, remote, next]


                        next true

                ,

                    (next)=> # custom check function - must callback true to permit!
                        if typeof (check = conf.permissions) is 'function' || check = conf.permissions?.check

                            check conf, sock, remote, next

                        else next true

                ,
                    (next)=>

                        if conf.permissions?.token
                            remote.token (err, token)=>
                                next token && conf.permissions.token.indexOf(token) isnt -1

                        else next true

                ,
                    (next)=>

                        if conf.permissions?.tls
                            data = sock.getPeerCertificate()
                            for key, list of conf.permissions.tls
                                val = floyd.tools.objects.resolve key, data
                                if !val || list.indexOf(val) is -1
                                    return next false

                            next true
                        else next true

                ]

                permit = (ok)=>
                    return fn(new floyd.error.Forbidden @ID) if !ok

                    if check = checks.shift()
                        check permit

                    else fn()

                # start recursion

                permit true
