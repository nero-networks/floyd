
module.exports =

    ##
    ## @class floyd.stores.Context
    ##
    class StoreContext extends floyd.Context
        
        init: (config, done)->
            super config, (err)=>
                return done(err) if err
        
                # instantiate store engine
                if (type = @data.type || 'Store') is 'Store'
                    @_engine = new floyd.stores.Store()
                    if config.memory
                        @_engine._memory = config.memory

                else
                    type = floyd.tools.strings.capitalize(type)+'Store'
                
                    if !floyd.stores.engines[type]
                        return @logger.error new floyd.error.Exception 'Invalid store type '+type

                    @_engine = new floyd.stores.engines[type]()
            
                @_settings = 
                    type: type
                    pk: @data.pk||'id'
                    
                done()
            
            
        ##
        ##
        ##
        boot: (fn)->
            super (err)=>
                return fn(err) if err
                            
                @_engine.init @data, fn

                

        ##
        ##
        ##
        stop: (fn)->
            super (err)=>
                if @_engine
                    @_engine.persist ()=>
                        @_engine.close?()
                        
                        process.nextTick fn if fn
            
                fn? err if err
            
        ##
        ## Get key, then callback fn(err, val).
        ##
        get: (key, fn)->
            @_engine.get(key, fn)


        ##
        ## Set key to entity, then callback fn(err).
        ##
        set: (key, entity, fn)->
            @_engine.set(key, entity, fn)


        ##
        ## Remove key, then callback fn(err).
        ##
        remove: (key, fn)->
            @_engine.remove(key, fn)


        ##
        ## Check if key exists, callback fn(err, exists).
        ##
        has: (key, fn)->
            @_engine.has key, fn


        ##
        ## Fetch number of keys, callback fn(err, len).
        ##
        length: (fn)->
            @_engine.length fn


        ##
        ## Clear all keys, then callback fn(err).
        ##
        clear: (fn)->
            @_engine.clear fn


        ##
        ## Clear all keys that expires, then callback fn(err).
        ##
        clear_expired: (fn)->
            @_engine.clear_expired fn


        ##
        ## Iterate with fn(val, key), then callback done() when finished.
        ##
        each: (fn, done)->
            @_engine.each fn, done
        
        
        ##
        ##
        ##
        keys: (fn)->
            @_engine.keys fn
            
            
        ##
        ##
        ##
        distinct: (field, query, fn)->
            if typeof query is 'function'
                fn = query
                query = null
                
            @_engine.distinct(field, query, fn)
            
        ##
        ## Find all entities where its field values matching corresponding query,
        ## then callback fn(err, entities).
        ##
        find: (query={}, options={}, fields, fn)->
            if typeof options is 'function'
                fn ?= options
                options = {}
                
            if typeof fields is 'function'
                fn ?= fields
                fields = null
            
            options.limit = null if options.limit is -1
            
            @_find query, options, fields, fn
            
        ##
        ##
        _find: (query, options, fields, fn)->
            @_engine.find query, options, fields, (err, res, _options, _fields, _query )=>
                fn err, res, (_options||options), (_fields||fields), (_query||query)
