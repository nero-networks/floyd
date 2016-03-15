
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
            
            super config
            
        ##
        ##
        ##
        publish: (data, done)->		
            @_process @_pool,				
                done: done 
                
                each: (handler, next)=>
                    try					
                        handler null,
                            origin: (@publish.identity || @identity).id
                            data: data
                        
                        next()
                        
                    catch err
                        console.log err
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
            
            @_pool.delete @_pool[token]
            
            #console.log 'unsubscribe', token, @_pool.length, @_pool
            
            if !@_pool.length
                #console.log 'offline event', @_pool.length
                
                @_emit 'pool:offline'
                
                if @_sampler?._timeout
                    clearTimeout @_sampler._timeout
                    @_sampler._timeout = null
            