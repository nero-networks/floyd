

module.exports =

    Client: (ctx, brokerId, handler)->
        new Client ctx, brokerId, handler


##
##
##
class Client

    ##
    ##
    ##
    constructor: (@_ctx, @_brokerId, topic, handler)->
        @__SUBS = {}

        if typeof topic is 'function'
            handler = topic
            topic = null

        if handler
            @__LEGACYsub = @subscribe topic, handler


    ##
    ##
    ##
    publish: (topic, data, done)->
        done ?= (err)=>
            @_ctx.logger.error(err) if err

        @_getBroker (err, broker)=>
            return done(err) if err

            broker.publish topic, data, done


    ##
    ##
    ##
    subscribe: (topic, handler)->

        sub =
            connect: ()=>
                if !sub.running
                    @_getBroker (err, broker)=>
                        return handler(err) if err

                        broker.subscribe topic, (err, msg)=>
                            return handler(err) if err

                            ## subscription
                            if msg.token
                                @_ctx.logger.debug 'connected:', msg
                                sub.token = msg.token
                                sub.running = true

                                @__SUBS[sub.token] = sub

                            else
                                ## message
                                @_ctx.logger.debug 'message received:', msg
                                handler null, msg
            disconnect: ()=>
                if sub.running
                    @_ctx.logger.debug 'disconnecting...'
                    @_getBroker (err, broker)=>
                        return @logger.error(err) if err

                        broker.unsubscribe sub.token

                    delete @__SUBS[sub.token]

                    sub.token = null
                    sub.running = false

        sub.connect()
        return sub

    ##
    ##
    ##
    _getBroker: (fn)->
        return fn(null, @_broker) if @_broker

        @_ctx.lookup @_brokerId, @_ctx.identity, (err, broker)=>
            return fn(err) if err

            fn null, @_broker = broker

            @_ctx.on 'shutdown', ()=>
                @disconnect()
                for token, sub of @__SUBS
                    sub.disconnect()

    ##
    ##
    ##
    connect: ()->
        @__LEGACYsub?.connect()
        @running = true


    ##
    ##
    ##
    disconnect: ()->
        @__LEGACYsub?.disconnect()
        @running = false
