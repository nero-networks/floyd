
events = require 'events'

module.exports = (handler)->

    ##
    ##
    pool = {}

    ##
    ##
    __token = null

    ##
    ##
    __user = null

    ##
    ##
    handler ?= new floyd.auth.Handler()

    ##
    ##
    emitter = new events.EventEmitter()
    emitter.setMaxListeners 100

    ##
    ##
    _on = emitter.addListener
    emitter.addListener = (action, listener)->
        _on.apply emitter, arguments

        if action is 'login' && __user
            listener __user

        if action is 'authorized' && __token
            listener __token


    ##
    ##
    ##
    authorize: __authorize = (token, fn)->
        #console.log 'authorizing', token

        emitter.emit 'authorized', __token = token

        handler.authorize token, (err, user)=>

            ## second handler call, session destroy
            if err?.message is 'session destroyed'

                if emitter.emit
                    emitter.emit 'logout'
                #console.log 'logout hook triggered'
                return __user = null

            ## first handler call, normal flow
            if !err
                #console.log 'post authorizing', token


                if __user = user
                    #console.log 'authorized user', __user

                    emitter.emit 'login', __user


            else if err

                emitter.emit 'unauthorized'

                #console.log 'authorize error', err

            fn? err

    ##
    ##
    ##
    createIdentity: (id)->
        #console.log floyd.tools.objects.keys(pool).length, 'create', id

        if !pool[id]
            return pool[id] = new floyd.auth.Identity id, emitter

        else
            throw new Error 'duplicate identity: '+id


    ##
    ##
    ##
    destroyIdentity: (identity, done)->
        id = identity.id

        if pool[id]
            delete pool[id]

            #console.log floyd.tools.objects.keys(pool).length, 'destroy', id

            if emitter.emit
                emitter.emit 'destroy:'+id

        else
            console.warn 'unmanaged identity', id

        done?()


    ##
    ##
    ##
    login: (user, pass, fn)->
        handler.login __token, user, pass, (err)=>
            #console.log 'LOGIN:', user
            return fn(err) if err

            __authorize __token, ()=>
                fn? null, true




    ##
    ##
    ##
    logout: (fn)->
        #console.log emitter, typeof emitter.emit

        handler.logout __token, (err)->
            return fn(err) if err
            __user = null

            if emitter.emit
                emitter.emit 'logout'

            fn()


    ##
    ##
    ##
    authenticate: (identity, fn)->

        if pool[identity.id] is identity
            #console.log 'authentic local identity', identity.id
            fn()

        else
            #console.log 'try handler for identity', identity.id
            handler.authenticate identity, fn

    ##
    ##
    ##
    destroy: (done)->
        #console.log 'manager.destroy', done
        done()
