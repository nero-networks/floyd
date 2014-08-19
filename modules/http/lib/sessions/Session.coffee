
events = require 'events'

module.exports =

    class Session 
    
        constructor: (@SID, config)->
            
            #console.log 'create session', @SID
            
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
        touch: ()->
            @touched = @public.touched = +new Date()
            
            #console.log 'touch session', @SID

            @emit 'touch', @touched 
            
        
        ##
        destroy: ()->
        
            #console.log 'destroy session', @SID
            
            @emit 'destroy'
        
        
        ##
        suspend: ()->
        
            #console.log 'suspend session', @SID
            
            @touch()
            
            @emit 'suspend'
 
 
        ##
        resume: ()->
        
            #console.log 'resume session', @SID

            @emit 'resume'
