
module.exports =

    class OMAExecutor

        constructor: (context)->
            @context = context
            @HIDDEN = ['lookup', 'on', 'once', 'off', 'addListener', 'removeListener', 'forIdentity']
            @IDENTITIES = {}

            @context.lookupLocal @context.data.find('authManager'), (err, sessions)=>
                @logger.error(err) if err
                @_sessions = sessions

        ##
        ##
        ##
        execute: (SID, o, m, a, fn)->
            if @HIDDEN.indexOf(m) > -1
                return fn('unknown method: '+o+'.'+m)
            @getIdentity SID, (err, ident)=>
                return fn(err) if err

                targetId = o.toLowerCase()
                if targetId is 'system'
                    @executeSystem SID, ident, o, m, a, fn

                else
                    @lookupTarget targetId, ident.identity, (err, target)=>
                        return fn(err) if err
                        if target[m] && @HIDDEN.indexOf(m) is -1
                            target[m].apply target, a.concat fn

                        else fn new Error 'unknown method '+m

        ##
        ## implement context._executeSystem to intercept calls to executeSystem
        ## context._executeSystem must return true when consumed!
        ##
        executeSystem: (SID, ident, o, m, a, fn)->

            ## try to delegate system call.
            ## context must return true when consumed
            if !@context._executeSystem SID, ident, o, m, a, fn
                ## login
                if m is 'login'
                    user = a[0]
                    pass = a[1]

                    if !SID
                        SID = floyd.tools.strings.uuid()
                        return @execute SID, o, m, a, fn ## recursion

                    ident.manager.login user, pass, (err)=>
                        if err
                            @_sessions._registry.destroy SID
                            return fn err

                        fn null, SID

                ## logout
                else if m is 'logout'
                    return fn() if !ident?.manager?.logout
                    ident.manager.logout ()=>
                        @_sessions._registry.destroy SID
                        fn()

                else fn new Error 'unknown method '+m

        ##
        ##
        ##
        lookupTarget: (id, identity, fn)->
            @context.lookup id, identity, fn

        ##
        ##
        ##
        getIdentity: (SID, fn)->
            ## no session ID provided
            return fn(null, identity:@context.identity) if !SID

            ## identity already registered
            return fn(null, @IDENTITIES[SID]) if @IDENTITIES[SID]

            ## create new identity
            @_sessions._load SID, (err, session)=>
                return fn(err) if err

                manager = new floyd.auth.Manager @context._createAuthHandler()

                @IDENTITIES[SID] = ident =
                    manager: manager
                    identity: manager.createIdentity @context.identity.id+'.'+SID
                    session: session.public

                session.on 'destroy', ()=>
                    delete @IDENTITIES[SID]
                    ident.manager.destroyIdentity ident.identity

                manager.authorize session.token, ()=>
                    fn null, ident
