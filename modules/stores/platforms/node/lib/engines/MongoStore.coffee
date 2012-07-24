
__OPTIONS = ['sort', 'skip']

module.exports =

    ##
    ## @class floyd.store.MongoStore
    ##
    class MongoStore extends floyd.stores.Store

        init: (options, fn)->
            mongoq = require 'mongoq'
            
            @_db = mongoq 'mongodb://localhost/'+options.name
            @_client = @_db.collection options.collection
            
            if !floyd.tools.objects.isArray(list = options.index)
                list = [list]
            
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
                

        get: (key, fn)->
            @_client.findOne _id:key, fn


        set: (key, item, fn)->
            item._id = key
            @_client.save item, fn


        remove: (key, fn)->
            @_client.remove _id:key, fn


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


        each: (fn, done)->
            @find {}, {}, null, (err, items)->
                for doc in items
                    fn doc, doc._id

                done?()

        
        distinct: (field, fn)->
            @_client.distinct field, fn

        find: (query, options, fields, fn)->			
            query ?= {}
            
            q = @_client.find(query)
            q.count (err, size)=>
                
                options ?= {}		
                
                for method in __OPTIONS
                    if options[method] && q[method]
                        q[method] options[method] 
                        
                for method, value of options
                    if __OPTIONS.indexOf(method) is -1 && q[method]
                        q[method] value
                        
                options.size = size
                
                q.toArray (err, items)=>				
                    
                    fn err, @_filterFields(items, fields), options, fields
