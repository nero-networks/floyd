
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
                                args = obj[m].toString()
                                args = args.substr 0, args.indexOf(')') + 1
                                args = args.replace /(\n)+/g, ''
                                args = args.match('.*?[(](.*)[)].*')[1].split ', '
                                args.pop()
                                args = args.join ', '

                                methods.push
                                    name: m
                                    args: args
                                    info: obj[m+'_']?.info || obj[m+'_']
                                    spec: if typeof obj[m+'_'] is 'string' then info: obj[m+'_'] else obj[m+'_']

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
            if req.uri is '/proxy.js'
                if !@__PROXY_FILE_CACHE
                    coffee = require 'coffeescript'
                    fs = require 'fs'
                    @__PROXY_FILE_CACHE = coffee.compile fs.readFileSync(__dirname+'/../../../tools/Proxy.coffee').toString()

                res.ctype = 'text/javascript'
                return fn null, @__PROXY_FILE_CACHE

            ##
            if req.session && !!(SID = req.session?.SID) && !(_ident = @_IDENTITIES[SID = req.session.SID])
                #console.log 'creating _ident for', SID
                manager = new floyd.auth.Manager @_createAuthHandler()

                @_IDENTITIES[SID] = _ident =
                    manager: manager
                    identity: manager.createIdentity @identity.id+'.'+SID

                req.session.on 'destroy', ()=>
                    #console.log 'deleting _ident', _ident.identity.id
                    _ident.manager.destroyIdentity _ident.identity
                    delete @_IDENTITIES[SID]

                manager.authorize req.session.TOKEN, ()=>
                    @_createContent req, res, fn

            else
                #console.log 'using _ident', _ident.identity?.id || 'no identity'
                _send = (err, response)->
                    obj =
                        response: response
                        error: if err then err.toString() else undefined

                    res.cache?.etag()
                    res.ctype = 'application/json'
                    res.send JSON.stringify(obj, null, 4)+'\n'

                floyd.tools.http.parseData req, (err)=>
                    return _send(err) if err

                    @_exec req.body.o, req.body.m, JSON.parse(req.body.a || '[]'), _ident, _send

        ##
        ##
        ##
        _exec: (o, m, a, _ident, fn)->
            if !(@_HIDDEN.indexOf(m) is -1)
                return fn('unknown method: '+o+'.'+m)

            ## login
            if o is 'System' && m is 'login'
                _ident.manager.login a[0], a[1], fn

            ## logout
            else if o is 'System' && m is 'logout'
                _ident.manager.logout fn

            ## find method
            else
                @_getObject o, (err, obj)=>
                    return fn(err) if err
                    try
                        a.push fn

                        if obj[m]
                            if _ident && obj.forIdentity
                                obj.forIdentity _ident.identity, (err, wrapper)=>
                                    return fn(err) if err

                                    wrapper[m].apply wrapper, a

                            else
                                obj[m].apply obj, a

                        else
                            fn new Error 'unknown method: '+o+'.'+m

                    catch err
                        @logger.error 'exec error in '+o, err
                        fn err.message || err


        ##
        ##
        ##
        _getObject: (o, fn)->

            if typeof (obj = @_registry[o]) is 'string'
                @lookup obj, @identity, fn

            else if typeof obj is 'function'
                obj fn

            else fn null, obj
