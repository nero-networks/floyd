

##
## @class floyd.auth.Identity
##
module.exports = (id, _manager)->
    manager = _manager

    events = require 'events'

    ##
    ##
    __token = null


    ## crittical datastorage. holds the data from the db
    ## --> not to be exposed directly to the outside world
    __user = null


    ##
    ## private emitter
    emitter = new events.EventEmitter()
    emitter.setMaxListeners 56 ## <-- dunno how many is good.. 56 is unique to identify warinings

    ##
    authorized = (token)->

        __token = token

     ##
    unauthorized = ()->

        __token = null



    ##
    login = (user)->
        __user = user

        emitter.emit 'login', __user?.login


    ##
    logout = ()->

        emitter.emit 'logout'

        __user = null


    ##
    destroy = ()->
        if manager?.removeListener
            #console.log authorized, login, logout, destroy
            manager.removeListener 'authorized', authorized
            manager.removeListener 'unauthorized', unauthorized
            manager.removeListener 'login', login
            manager.removeListener 'logout', logout
            manager.removeListener 'destroy:'+id, destroy

        floyd.tools.objects.process @,
            each: (key, value, next)=>
                @[key] = null
                next()

        emitter.emit 'destroyed'


    ##
    if manager?.addListener
        manager.addListener 'authorized', authorized
        manager.addListener 'unauthorized', unauthorized
        manager.addListener 'login', login
        manager.addListener 'logout', logout
        manager.addListener 'destroy:'+id, destroy



    ## public api object

    ##
    ##
    id: id


    ##
    ##
    ##
    token: (fn)->
        fn? null, __token
        return __token


    ##
    ##
    ##
    login: (fn)->
        fn? null, __user?.login
        return __user?.login


    ##
    ##
    ##
    data: (fn)->
        data = if __user then floyd.tools.objects.clone(__user) else {}

        fn? null, data

        return data



    ##
    ##
    ##
    hasRole: (roles, fn)->
        if typeof roles is 'string'
            roles = [roles]


        if __user?.roles
            for role in roles
                #console.log  __user.roles.indexOf(role), role
                if __user.roles.indexOf(role) != -1
                    fn? null, true
                    return true

        fn?()
        return false


    ##
    ##
    ##
    on: (action, handler)->
        emitter.addListener action, handler

        if action is 'login' && _login = __user?.login
            handler _login

    ##
    ##
    ##
    off: (action, handler)->
        emitter.removeListener action, handler


    ##
    ##
    ##
    once: (action, handler)->

        @on action, proxy = (args...)=>
            @off action, proxy

            handler.apply null, args
