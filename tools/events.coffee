
events = require 'events'

module.exports = 

    ##
    ##
    ##
    Emitter: (parent, interceptor)->
        
        parent ?= new events.EventEmitter()
        
        interceptor ?= (parent, name, method, args..., fn)->
            fn name, method, args
        
        floyd.tools.objects.proxy parent, (name, method, args...)->
            
            interceptor.apply @, [parent, name, method].concat(args).push (name, method, args)->
            
                method.apply parent, args
                
    
    ##
    ##
    ##
    Listener: (emitter, action, handler)->
    
        listener =
            on: ->
                emitter.on action, handler
                @OFF = !(@ON = true)
                return @			
            off: ->
                emitter.off action, handler
                @ON = !(@OFF = true)
                return @			
            
            toggle: ->
                if @ON then @off() else @on()
                return @			
        
        
        listener.on()
