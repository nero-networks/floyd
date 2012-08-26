
module.exports =

    class Registry 
    
        constructor: (@_config)->
        
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
        _observe: ()->
            
            @_running = setInterval ()=>
                
                if !(keys = floyd.tools.objects.keys @_pool).length
                    clearInterval @_running
                    @_running = null
                
                else
                
                    now = +new Date()
                    
                    #console.log 'starting cleanup run:', now, keys
                    
                    for sid in keys
                        do (sid)=>
                            sess = @_pool[sid]
                            
                            #console.log 'check session', (sess.touched + @_config.timeout * 1000) < now, sess
                                    
                            if (sess.touched + @_config.timeout * 1000) < now
                                sess.destroy()
                                delete @_pool[sid]
                
            , @_config.interval * 1000
        
            