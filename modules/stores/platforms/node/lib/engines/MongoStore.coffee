
__OPTIONS = ['sort', 'skip']

module.exports =

    ##
    ## @class floyd.store.MongoStore
    ##
    class MongoStore extends floyd.stores.Store

        init: (options, fn)->
            mongoq = require 'mongoq'
            
            @_db = mongoq 'mongodb://'+(options.host || 'localhost')+'/'+options.name, (options.options || w:1)
            @_client = @_db.collection options.collection
            
            if (list = options.index)
                if !floyd.tools.objects.isArray list 
                    list = [list]
                
                for idx in list
                    
                    if typeof idx is 'string'
                        name = idx
                        idx = {}
                        idx[name] = 1
                        
                    @_client.ensureIndex idx, []
            
            fn()
                
        close: (fn)->
            @_db.close()
            fn?()
        
        get: (key, fn)->
            @_client.findOne _id:key.toString(), fn


        set: (key, item, fn)->
            item._id = key.toString()
            @_client.save item, fn


        remove: (key, fn)->
            @_client.remove _id:key.toString(), fn


        has: (key, fn)->
            @get key, (err, exists)->
                fn err, !!exists

        length: (fn)->
            @_client.count fn


        clear: (fn)->
            @_client.remove fn


        cleanup: (fn)->
            query = {}
            query[@_options.cleanup.field] = $lte: +new Date()
            @_client.remove query, fn

        
        distinct: (field, query, fn)->
            @_client.distinct field, query, fn

        find: (query, options, fields, fn)->	
    
            #console.log 'query', query, options, fields
            q = @_client.find(query)
            q.count (err, size)=>
                return fn(err) if err
                #console.log 'size', size
                options ?= {}		
                
                options.skip = options.offset
                
                for method in __OPTIONS
                    if options[method] && q[method]
                        q[method] options[method] 
                        
                for method, value of options
                    if __OPTIONS.indexOf(method) is -1 && q[method]
                        q[method] value
                        
                options.size = size
                
                q.toArray (err, items)=>				
                    return fn(err) if err
                    process.nextTick ()=>
                        fn null, @_filterFields(items, fields), options, fields
                        