
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
            

        get: (key, fn)->
            fn null, @_memory[key]


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
            
                for key, val of items
                    fn val, key

                done?()

        
        distinct: (field, query, fn)->
            throw new Error 'unimplemented'
        
        find: (query, options, fields, fn)->
            
            if query == {} || !query
                items = _(@_memory).values()
            
            else 
                items = _(@_memory).select (item)->
        
                    for key, value of query
                        if !item[key] || (_.isRegExp(value) && !item[key].match(value)) || item[key] != value
                            return false
                             
                    return true
            
            options ?= {}
            if items
                options.size = items.length
                        
                if options.sort
                    for sortby, dir of options.sort
                        dir ?= 1
                        
                        items.sort (a, b)->
                            console.log a[sortby], b[sortby]
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
                        if field						## CHECK: wozu ist das? fields mit null-values?
                            _item[field] = item[field] 
            
                return _items
            
            else

                return items || []
            