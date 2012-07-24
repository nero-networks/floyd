
module.exports = 

    class PubSubContext extends floyd.Context
        
        ##
        ##
        ##
        constructor: (config, parent)->
            super config, parent
            
            @_pool = new floyd.data.MappedCollection()
            
        
        ##
        ##
        ##
        publish: (data, done)->		

            @_process @_pool,				
                done: done 
                
                each: (handler, next)=>
                    try					
                        
                        handler null,
                            origin: @publish.identity.id
                            data: data
                        
                        next()
                        
                    catch err
                        @unsubscribe handler.id
            
            
            
        ##
        ##
        ##
        subscribe: (handler)->

            handler null, 
                token: handler.id = floyd.tools.strings.uuid()

            filled = @_pool.length
            
            @_pool.push handler

            #console.log 'subscribe', filled, @_pool
            
            if !filled
                #console.log 'online event', @_pool.length
                
                @_emit 'pool:online'

            
            
        ##
        ##
        ##
        unsubscribe: (token)->				
            
            @_pool.delete @_pool[token]
            
            #console.log 'unsubscribe', token, @_pool.length, @_pool
            
            if !@_pool.length
                #console.log 'offline event', @_pool.length
                
                @_emit 'pool:offline'
                
