
module.exports =

    class PersisedRegistry extends floyd.http.sessions.Registry
        
        ##
        ##
        ##        
        constructor: (@_config)->
            super @_config
            
            @__store = @_config.store || '.floyd/sessions-store.json'
                        
            if !floyd.tools.files.exists @__store
                floyd.tools.stores.write 'registry', {}, @__store
                
                if process.getuid() is 0
                    floyd.tools.files.chown @__store, floyd.system.UID, floyd.system.GID
                    
            floyd.tools.objects.process floyd.tools.stores.read('registry', @__store),
                
                each: (id, data, next)=>

                    sess = new (floyd.tools.objects.resolve @_config.sessions.type) id, @_config.sessions
                    
                    floyd.tools.objects.extend sess, data
                    
                    @add sess
                    
                    next()
                    
                done: (err)=>
                    throw err if err
                    
                    floyd.tools.stores.write 'registry', {}, @__store
                    
                    
                    
                    
        ##
        ##
        ##  
        persist: ()->
            
            floyd.tools.stores.write 'registry', @_pool, @__store
            
        