
module.exports =

    ##
    ## 
    ##
    class ObjectStore extends floyd.stores.Store
    
        ##
        ##
        ##
        init: (options, done)->
            super options, (err)=>
                return done(err) if err                
                
                done()
                
                
        ##
        ##
        ##      
        get: (key, fn)->        
            
            fn null, floyd.tools.objects.find key, @_memory
        
        
        ##
        ##
        ##      
        set: (key, entity, fn)->
            
            floyd.tools.objects.write key, entity, @_memory

            fn()
            
            