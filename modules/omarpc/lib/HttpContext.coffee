
##
##
##

module.exports =

    class OmaRpcHttpContext extends floyd.http.Context

        ##
        ##
        ##
        configure: (config)->

            config = super new floyd.Config

                registry: {}

                data:
                    route: '/RpcServer'
                    authManager: 'sessions'

            ,config

            @_IDENTITIES = {}

            (@_HIDDEN = config.data.hiddenMethods || []).push 'lookup', 'on', 'once', 'off', 'addListener', 'removeListener', 'forIdentity'

            @_registry = config.registry

            @_registry.System =
                ##
                list_: 'list all available objects (modules)'
                list: (fn)=>
                    modules = []
                    for n, m of @_registry
                        modules.push n
                    fn null, modules

                ##
                info_: 'get info about a specific object'
                info: (module, fn)=>

                    if typeof module is 'function'
                        return module new Error 'no object name'

                    if !@_registry[module]
                        return fn new Error 'unknown object '+module

                    @_getObject module, (err, obj)=>
                        return fn(err) if err

                        methods = []
                        for m, d of obj
                            if typeof obj[m] is 'function' && @_HIDDEN.indexOf(m) is -1
                                args = obj[m].toString().match('.*?[(](.*)[)].*')[1].split ', '
                                args.pop()

                                methods.push
                                    name: m
                                    args: args.join ', '
                                    info: obj[m+'_']

                        fn null,
                            module: module
                            methods: methods

                ## fake methods
                login_: 'authenticate floyd session by logging in with username and password'
                login: (user, pass, fn)->

                logout_: 'de-authenticate authenticated floyd session'
                logout: (fn)->

            return config


        ##
        ##
        ##
        _createContent: (req, res, fn)->

            ##
            if req.session && !(_ident = @_IDENTITIES[SID = req.session?.SID])
                #console.log 'creating _ident'

                manager = new floyd.auth.Manager @_createAuthHandler()

                @_IDENTITIES[SID] = _ident =
                    manager: manager
                    identity: manager.createIdentity @identity.id+'.'+SID

                req.session.on 'destroy', ()=>
                    _ident.manager.destroyIdentity _ident.identity
                    delete @_IDENTITIES[SID]

                manager.authorize req.session.TOKEN, (err)=>
                    @_createContent req, res, fn

            else
                #console.log 'using _ident', _ident.identity.id

                floyd.tools.http.parseData req, (err)=>
                    return fn(err) if err

                    res.cache?.etag()
                    ##
                    m = req.body.m
                    a = JSON.parse(req.body.a || '[]')

                    a.push _send = (err, response)->

                        obj =
                            response: response
                            error: if err then err.toString() else undefined

                        res.ctype = 'application/json'
                        res.send JSON.stringify(obj, null, 4)+'\n'

                    ## login
                    if req.body.o is 'System' && m is 'login'
                        _ident.manager.login a[0], a[1], _send

                    ## logout
                    else if req.body.o is 'System' && m is 'logout'
                        _ident.manager.logout _send

                    ## find method
                    else
                        @_getObject req.body.o, (err, o)=>
                            return fn(err) if err
                            try
                                if _ident && o.forIdentity
                                    o.forIdentity _ident.identity, (err, wrapper)=>
                                        return fn(err) if err

                                        wrapper[m].apply wrapper, a

                                else if o?[m]

                                    o[m].apply o, a

                                else
                                    _send 'unknown method: '+o+'.'+m

                            catch err
                                _send err
        ##
        ##
        ##
        _getObject: (o, fn)->

            if typeof (obj = @_registry[o]) is 'string'
                @lookup obj, @identity, fn

            else if typeof obj is 'function'
                obj fn

            else fn null, obj
