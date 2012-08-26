
module.exports =

    class PersisedRegistry extends floyd.http.sessions.Registry
        
        ##
        ##
        ##        
        constructor: (@_config)->
            super @_config
            
            @__store = @_config.store || '.floyd/sessions-store.json'
            
            floyd.tools.objects.process floyd.tools.stores.read('registry', @__store),
                
                each: (id, data)=>
                    
                    @add id, sess = new (floyd.tools.objects.resolve @_config.sessions.type) id, @_config.sessions, data
                    
                done: (err)=>
                    throw err if err
                    
                    if floyd.tools.files.fs.existsSync
                        
                        floyd.tools.files.fs.unlinkSync @__store
        
        ##
        ##
        ##  
        persist: ()->
            
            floyd.tools.stores.write 'registry', @_pool, @__store
            
        