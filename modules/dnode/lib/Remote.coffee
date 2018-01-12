
##
##
##
module.exports =

    class DNodeRemote extends floyd.Context

        ##
        ##
        ##
        _useProxy: (conf, proxy)->

            ##
            ## initial call
            if !@_proxy
                @_proxy = proxy

                ## prepare __wrappers
                @__wrappers = {}

                ## reset the id
                @ID = @parent.ID + '.' + (@id = @_proxy.id)

                ## recreate the logger
                @logger = @_createLogger @ID

                ##
                ##
                if conf.keepalive && proxy.ping
                    clearInterval(@_interval) if @_interval

                    @logger.debug 'setting keep-alive interval to', conf.keepalive

                    @_interval = setInterval ()=>
                        @logger.fine 'sending keep-alive ping'
                        @_proxy.ping ()=>
                            @logger.fine 'pong'
                    , conf.keepalive


            ##
            ## subsequent calls on reconnect
            else
                @_proxy = proxy

                ## rewrap active lookups
                for name, wrappers of @__wrappers
                    do (name, wrappers)=>

                        for id, wrapper of wrappers
                            do (id, wrapper)=>

                                wrapper.rewrapping = true

                                @lookup name, wrapper.identity, (err, ctx)=>
                                    wrapper.error(err) if err

        ##
        ##
        ##
        stop: (done)->
            if @_interval
                @logger.debug 'stopping keep-alive interval'
                clearInterval(@_interval) if @_interval
            super done

        ##
        ##
        ##
        lookup: (name, identity, fn, noremote)->

            ## local lookup
            if noremote
                super name, identity, fn

            ## cache lookup
            else if (wrapper = @__wrappers[name]?[identity.id]) && !wrapper.rewrapping
                fn null, wrapper.ctx

            ## remote lookup
            else
                @_proxy.lookup name, identity, (err, ctx)=>
                    return fn(err) if err

                    fn null, @_wrapRemote name, identity, ctx, fn

                , true ## <-- this is the noremote flag



        ##
        ##
        ##
        _wrapRemote: (name, identity, ctx, error)->

            ## create reusable wrapper
            wrapper = (@__wrappers[name] ?= {})[identity.id] ?=
                error: error
                identity: identity
                ctx: {}

            ## fill wrapper
            for key, value of ctx
                wrapper.ctx[key] = value

            ##
            if wrapper.rewrapping
                wrapper.rewrapping = false

                ## delete unknown keys in case of changes in remote api
                for key, value of wrapper.ctx
                    delete wrapper.ctx[key] if !ctx[key]

            ##
            return wrapper.ctx
