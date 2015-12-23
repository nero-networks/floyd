
module.exports =

    ##
    ## @class floyd.stores.Store
    ##
    class Store
        
        init: (@_options, fn)->
            @_memory ?= {}
            
            ## cleanup interval
            if _interval = @_options.cleanup?.interval || -1 > 0

                @_cleanup_interval = setInterval ()=>

                    @cleanup()
                    
                , _interval * 1000
                    
            
            fn()

        persist: (fn)->
            if @_cleanup_interval
                clearInterval @_cleanup_interval
                
            fn?()
        
        close: (fn)->
            fn?()

        get: (key, fn)->
            fn null, floyd.tools.objects.clone @_memory[key]


        set: (key, item, fn)->
            @_memory[key] = item

            fn?(null, @_memory[key])


        remove: (key, fn)->
            delete @_memory[key] if @_memory[key]

            fn?()


        has: (key, fn)->
            fn null, @_memory.hasOwnProperty(key)


        length: (fn)->
            fn null, _.keys(@_memory).length


        clear: (fn)->
            @_memory = {}

            fn?()


        cleanup: (fn)->
            date = +new Date()

            @each (val, key)->
                _expires = val[@_options.cleanup.field]
                if _expires > 0 && _expires < date
                    @remove key
            , fn


        each: (fn, done)->
            
            @find {}, {}, null, (err, items)=>
                return done(err) if err

                floyd.tools.objects.process items,
                    each: fn
                    done: done
        
        
        keys: (fn)->
            keys = []
            for key, val of @_memory
                keys.push key
            
            fn null, keys
            
        
        distinct: (field, query, fn)->
            throw new Error 'unimplemented'
        
        find: (query, options, fields, fn)->
            _items = floyd.tools.objects.values(@_memory)
            
            
            if !query || floyd.tools.objects.isEmpty query 
                items = _items 
            
            else 
                items = []                
                
                for item in _items
                    for key, value of query
                        if item[key] && (item[key] is value || item[key].match value)
                            items.push item
        
            options ?= {}
            if items
                options.size = items.length
                        
                if options.sort
                    for sortby, dir of options.sort
                        dir ?= 1
                        
                        items.sort (a, b)->
                            #console.log a[sortby], b[sortby]
                            if a[sortby] > b[sortby]
                                return dir
                                
                            if a[sortby] < b[sortby]
                                return dir * -1
                            
                            return 0
                                
    
                if options.limit
                    items = items.slice 0, options.limit
            
                items = @_filterFields items, fields
            
            if options.each
                for item in items
                    fn null, item, options, fields, query
                
                if options.each.indexOf && options.each.indexOf 'terminate' != -1
                    fn null, null, options, fields, query
                
            else
                fn null, items, options, fields, query
            
        
        
        ##
        ##
        ##
        _filterFields: (items, fields)->
            
            
            if items && fields
                _items = []
                
                for item in items				
                    _items.push _item = {}
                    
                    for field in fields							
                        if field || field is 0
                            _item[field] = item[field] 
            
                return _items
            
            else

                return items || []
            