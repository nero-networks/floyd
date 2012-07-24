
module.exports =

    class ObjectPool
    
        ##
        ##
        ##
        constructor: (@_config, @_create)->
            if typeof @_config is 'function'
                [@_config, @_create] = [@_create, @_config]
            
            @_pool = @_config.pool || []
            @_config ?= {}
            @_config.size ?= 15
        
        ##
        ##
        ##
        obtain: (args..., fn)->			
            if @_pool.length
                fn null, @_pool.pop()
                
            else
                args.push fn
                @_create.apply @, args
                
            
        
        ##
        ##
        ##
        release: (obj)->			
            
            if @_pool.length < @_config.size
                @_pool.push obj
                
                return true
                
    
            console.warn 'pool is full... releasing object'
            
            return false