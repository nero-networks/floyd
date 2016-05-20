
module.exports =

    class PubSubContext extends floyd.Context

        ##
        ##
        ##
        configure: (config)->

            @_pool = new floyd.data.MappedCollection()

            if typeof (@_sampler = config.sampler) is 'function'
                @_sampler =
                    tick: @_sampler

            @_trigger = config.trigger || {}

            super config

        ##
        ##
        ##
        stop: (done)->
            super (err)=>
                return done(err) if err

                for topic, trigger of @_trigger
                    trigger.offline?.apply @, []

                done()

        ##
        ##
        ##
        publish: (topic, data, done)->
            if typeof data is 'function'
                done = data
                data = null
            if !data
                data = topic
                topic = '_LEGACY_'

            threads = []
            @_process @_pool,
                ##
                each: (handler, next)=>
                    if topic.match handler.topic
                        threads.push (fn)=>
                            try
                                handler null,
                                    origin: (@publish.identity || @identity).id
                                    data: data

                                fn()

                            catch err
                                console.log err
                                @unsubscribe handler.id

                    next()

                ##
                done: (err)=>
                    return done(err) if err
                    done ?= (err)=>
                        return @logger.error(err) if err

                    floyd.tools.parallel threads, done


        ##
        ##
        ##
        subscribe: (topic, handler)->
            if typeof topic is 'function'
                handler = topic
                topic = null
            if !topic
                topic = '.*'

            if !handler
                throw new Error 'API Error: no handler specified. check api usage of PubSubContext.subscribe(topic, handler)'

            handler.id = floyd.tools.strings.uuid()
            handler.topic = topic

            @logger.fine 'subscribe event', topic

            handler null,
                token: handler.id

            filled = @_pool.length

            @_pool.push handler

            #console.log 'subscribe', filled, @_pool, @_trigger

            for _topic, trigger of @_trigger

                if _topic.match topic
                    if !trigger.__counter
                        trigger.__counter = 0

                        trigger.online?.apply @, [topic]

                    trigger.subscribe?.apply @, [topic, handler]

                    trigger.__counter++

            if !filled
                #console.log 'online event', @_pool.length

                @_emit 'pool:online'

                ##
                ## using timeout instead of interval offers the possibility to change
                ## the sampling rate between ticks or even the tick method itsself
                ##
                if @_sampler?.tick
                    tick = ()=>
                        if @_pool.length
                            @_sampler._timeout = setTimeout tick, @_sampler.rate || 1000

                            @_sampler.tick.apply @, []

                    ## initialize the loop
                    tick()



        ##
        ##
        ##
        unsubscribe: (token)->

            if topic = @_pool[token]?.topic
                @logger.fine 'unsubscribe event', topic

                for _topic, trigger of @_trigger
                    if _topic.match topic
                        trigger.unsubscribe?.apply @, [topic, @_pool[token]]

                        trigger.__counter--
                        if !trigger.__counter
                            trigger.offline?.apply @, [topic]

                @_pool.delete @_pool[token]

            #console.log 'unsubscribe', token, @_pool.length, @_pool

            if !@_pool.length
                #console.log 'offline event', @_pool.length

                @_emit 'pool:offline'

                if @_sampler?._timeout
                    clearTimeout @_sampler._timeout
                    @_sampler._timeout = null
