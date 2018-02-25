
module.exports =

    class Registry

        constructor: (@_config, parent)->

            @_pool = {}
            @_running = null

        ##
        add: (sess)->
            if sess.SID
                @_pool[sess.SID] = sess

                @_observe() if !@_running


        ##
        get: (id)->
            @_pool[id]?.touch()
            @_pool[id]

        ##
        createSID: (fn)->
            if @_pool[sid = floyd.tools.strings.uuid()]
                return @createSID fn

            fn null, sid

        ##
        destroy: (id)->
            if(@_pool[id])
                try
                    @_pool[id].destroy()
                catch e
                    console.warn e.message
                delete @_pool[id]

        ##
        _observe: ()->

            @_running = setInterval ()=>

                if !(keys = floyd.tools.objects.keys @_pool).length
                    clearInterval @_running
                    @_running = null

                else

                    now = +new Date()

                    #console.log 'starting cleanup run:', now, keys

                    for sid in keys
                        sess = @_pool[sid]

                        #console.log 'check session', (sess.touched + @_config.timeout * 1000) < now, sess

                        if (sess.touched + @_config.timeout * 1000) < now
                            @destroy sid

            , @_config.interval * 1000
