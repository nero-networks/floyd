
shoe = require('shoe')
dnode = require('dnode')

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
                    parent: false
                    ports: []
                    gateways: (if floyd.system.platform is 'remote' then ['remote'] else [])
                    route: '/dnode'

            , config

            if config.data.parent
                config.data.ports.push parent: true

            ## hack to delegate lookups to origin

            if origin = config.ORIGIN

                floyd.tools.objects.intercept @, 'lookup', (name, identity, fn, lookup)=>

                    #console.log 'lookup', name

                    lookup name, identity, (err, ctx)=>
                        if ctx
                            fn(null, ctx)

                        else
                            #console.log 'retry lookup', origin+'.'+name, err.message
                            lookup origin+'.'+name, identity, fn



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

                    reconn = require('reconnect-core') ()=>
                        if conf.tls
                            @logger.info 'connecting to tls-gateway:', conf.host||'localhost', conf.port
                        else
                            @logger.info 'connecting to gateway:', conf

                        c = @_createConnection conf

                        c.on 'error', (err)=>
                            @logger.error err

                        d = @_createLocal next
                        d.pipe(c).pipe d

                        return c

                    reconn().connect()


        ##
        ##
        ##
        _createConnection: (conf)->
            if conf is 'remote'
                shoe @data.route
            else if conf.tls
                require('tls').connect conf
            else
                require('net').connect conf

        ##
        ##
        ##
        _listen: (fn)->

            @_process @data.ports,

                done: fn

                each: (conf, next)=>
                    if conf.tls
                        @logger.info 'listening on tls-port:', conf.host||'localhost', conf.port
                    else
                        @logger.info 'listening on port:', conf

                    handler = (err)=>
                        fn(err) if err

                    if conf.parent

                        parent = @parent
                        while parent && !(server = parent.server) && parent.parent
                            parent = parent.parent

                        @_createServerSocket parent.server, handler

                    else if conf.child

                        @_createServerSocket @children[conf.child], handler

                    else if conf.ctx

                        @lookup conf.ctx, @identity, (err, ctx)=>

                            @_createServerSocket ctx.server, handler

                    else if conf.tls
                        require('tls').createServer conf, (c)=>
                            d = @_createLocal(handler)
                            c.pipe(d).pipe(c)

                            c.on 'error', handler

                        .listen conf.port, conf.host

                    else
                        @_createLocal(handler).listen conf

                    ##
                    next()

        ##
        ##
        ##
        _createServerSocket: (server, handler)->

            sock = shoe (stream)=>
                d = @_createLocal handler

                d.pipe(stream).pipe d

            sock.install server, @data.route



        ##
        ##
        ##
        _createLocal: (fn)->

            ##
            root = @parent || @

            ##
            dnode (proxy, conn)=>

                child = null

                conn.on 'remote', (remote)=>

                    if !(child = root.children[remote.id])
                        child = new floyd.dnode.Remote root

                        child.init (id: remote.id, type:'dnode.Remote'), (err)=>
                            return fn(err) if err

                        child._useProxy remote

                        root.children.push child

                        fn()

                    else
                        child._useProxy remote

                    ##
                    @_emit 'connected',
                        id: child.id

                    ##
                    conn.on 'end', ()=>
                        @_emit 'disconnected',
                            id: child.id


                    ##
                    conn.on 'error', (err)=>

                        console.log 'conn error!', err

                        fn err



                ## remote api
                id: root.id

                lookup: (args...)=>
                    child.lookup.apply child, args
