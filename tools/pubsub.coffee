
module.exports =

    Client: (ctx, brokerId, handler)->

        ctx.lookup brokerId, ctx.identity, (err, manager)=>
            manager.subscribe (err, msg)=>
                return handler(err) if err

                ## subscription
                if msg.token
                    ctx.logger.debug 'connected:', msg

                    ctx.on 'shutdown', ()=>
                        ctx.logger.debug 'unsubscribing...'
                        manager.unsubscribe msg.token

                else
                    ## message
                    ctx.logger.debug 'message received:', msg
                    handler null, msg

            ##
            @publish = (args...)->
                manager.publish.apply manager, args
