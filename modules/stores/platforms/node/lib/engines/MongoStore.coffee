
__OPTIONS = ['sort', 'skip', 'limit']
__NUMOPTIONS = ['skip', 'limit']

module.exports =

    ##
    ## @class floyd.store.MongoStore
    ##
    class MongoStore extends floyd.stores.Store

        _connect: (options, fn)->
            mongodb = require 'mongodb'
            mongodb.MongoClient.connect 'mongodb://'+(options.host || 'localhost')+'/'+options.name, fn

        init: (options, fn)->

            @_options = options.options || w:1

            @_connect options, (err, db)=>
                return fn(err) if err
                @_db = db
                @_client = @_db.collection options.collection

                if (list = options.index)
                    if !floyd.tools.objects.isArray list
                        list = [list]

                    for idx in list

                        if typeof idx is 'string'
                            name = idx
                            idx = {}
                            idx[name] = 1

                        @_client.ensureIndex idx, @_options

                fn()

        close: (fn)->
            @_db?.close()
            fn?()

        get: (key, fn)->
            @_client.findOne {_id:key}, fn


        set: (key, item, fn)->
            item._id = key.toString()
            @_client.save item, @_options, fn


        remove: (key, fn)->
            @_client.remove _id:key.toString(), @_options, fn


        has: (key, fn)->
            @get key, (err, exists)->
                fn err, !!exists

        length: (fn)->
            @_client.count {}, null, fn


        clear: (fn)->
            @_client.deleteMany {}, @_options, fn


        cleanup: (fn)->
            query = {}
            query[@_options.cleanup.field] = $lte: +new Date()
            @_client.remove query, fn


        distinct: (field, query, fn)->
            @_client.distinct field, query, null, fn

        find: (query, options, fields, fn)->

            #console.log 'query', query, options, fields
            q = @_client.find(query)
            q.count (err, size)=>
                return fn?(err) if err

                #console.log 'size', size
                options ?= {}
                options.skip ?= options.offset || 0
                options.size = size

                if !size
                    return fn null, [], options, fields

                for method in __NUMOPTIONS
                    if options[method] && typeof options[method] isnt 'number'
                        options[method] = floyd.tools.numbers.parse options[method]

                for method in __OPTIONS
                    if options[method] && q[method]
                        #console.log options[method] , q[method]
                        q[method] options[method]

                for method, value of options
                    if __OPTIONS.indexOf(method) is -1 && q[method]
                        q[method] value

                if fn
                    setImmediate ()=>
                        q.toArray (err, items)=>
                            return fn(err) if err
                            setImmediate ()=>
                                fn null, @_filterFields(items, fields), options, fields
