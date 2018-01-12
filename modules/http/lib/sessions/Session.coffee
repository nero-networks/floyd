
events = require 'events'

module.exports =

    class Session

        constructor: (SID, config)->
            #console.log 'create session', @SID
            @SID = SID
            @token = floyd.tools.crypto.hash(floyd.tools.strings.uuid()+@SID)+@SID

            emitter = new events.EventEmitter()

            @emit = (args...)=> emitter.emit.apply emitter, args
            @on = @addListener = (args...)=> emitter.addListener.apply emitter, args
            @off = @removeListener = (args...)=> emitter.removeListener.apply emitter, args

            @public =
                SID: @SID
                TOKEN: @token
                on: (args...)=> @addListener.apply @, args
                off: (args...)=> @removeListener.apply @, args
                once: (action, handler)=>
                    @on action, _handler = (event)=>
                        @off _handler
                        handler event

                ##
                has: (key, fn)=>
                    @touch()
                    fn null, !!@public[key] || @public[key] is 0 || @public[key] is false

                ##
                get: (key, fn)=>
                    @touch()
                    fn null, @public[key]

                ##
                set: (key, value, fn)=>
                    @touch()
                    @public[key] = value
                    fn()

        ##
        touch: ()->
            @touched = @public.touched = +new Date()

            #console.log 'touch session', @SID

            @emit 'touch', @touched


        ##
        destroy: ()->

            #console.log 'destroy session', @SID

            @emit 'destroy'
