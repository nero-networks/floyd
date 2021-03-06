util = require 'util'

module.exports = objects =

    ##
    ##
    ##
    promisify: (obj, target)->
        if floyd.tools.objects.isFunction obj
            return (args...)->
                new Promise (resolve, reject)->
                    args.push (err, res...)->
                        return reject(err) if err
                        resolve.apply null, res
                    obj.apply target, args

        else if floyd.tools.objects.isObject obj
            proxy = {}
            objects.process obj,
                each: (key, value, next)->
                    if typeof value is 'function'
                        wrapper = (args...)->
                            obj[key].apply obj, args
                        proxy[key] = objects.promisify wrapper, obj
                    else
                        proxy[key] = value

                    next()

            return proxy

        else
            return Promise.resolve obj


    ##
    ##
    ##
    keys: (objs...)->
        ## empty
        if !objs.length
            return []

        ## only one -> return its keys
        if objs.length = 1
            return (key for key of objs[0])

        ## many -> concat distinct
        keys = objects.keys objs.pop()

        if objs.length
            for obj in objs
                for key in objects.keys obj # length 1 recursion
                    if keys.indexOf(key) is -1
                        keys.push key

        return keys



    ##
    ##
    ##
    values: (obj)->
        return (val for k,val of obj)


    ##
    ## iterates over an array of items asynchronously.
    ## calls *each* with every item
    ## and finally *done* after all items are processed.
    ##
    process: (obj, {each, done})->
        done ?= (err)-> console.error(err) if err

        array = false

        iter = []

        ##
        next = (err)->
            done(err) if err

            return done() if !iter.length

            try
                if array
                    each iter.shift(), next

                else
                    each (key=iter.shift()), obj[key], next
            catch e
                next e
        ##
        if floyd.tools.objects.isArray obj
            array = true

            iter.push item for item in obj

        else
            iter.push key for key, val of obj
            ## ES6 class prototype methods
            iter.push key for key in objects.methods obj

        ##
        next()


    ##
    ##
    ##
    flatten: (obj, map, prefix)->
        map ?= {}

        if obj
            for k, v of obj
                key = if prefix then prefix+'.'+k else k
                if floyd.tools.objects.isObject v
                    objects.flatten v, map, key
                else
                    map[key] = v

        return map

    ##
    ##
    ##
    methods: (obj, list)->
        list ?= []
        if obj
            proto = Object.getPrototypeOf obj
            if proto && Object.getPrototypeOf proto
                for key in Object.getOwnPropertyNames proto
                    if key isnt 'constructor' && list.indexOf(key) is -1
                        list.push key
                objects.methods proto, list
        return list

    ##
    ## shuffle the order of an array randomly
    ##
    shuffle: (arr) ->
        i = arr.length
        while --i > 0
            j = ~~(Math.random() * (i + 1))
            temp = arr[j]
            arr[j] = arr[i]
            arr[i] = temp

        return arr

    ##
    ## extract an index out of an object (or array)
    ##
    ## cut([1,2,3], 1) will splice the array to [1,3] and return 2
    ##
    ## while
    ## cut({x:1,y:2,secret:'geheim'}, 'secret') will delete obj.secret and return 'geheim'
    ##
    cut: (obj, key)->

        if obj && data=obj[key]
            if objects.isArray obj
                obj.splice key, 1

            else
                delete obj[key]

            return data

    ##
    ##
    ##
    unlink: (obj, key)->
        for key, value of obj
            obj[key] = null

        return null

    ##
    ##
    ##
    cleanup: (obj)->
        for key, value of obj

            if !value
                delete obj[key]

            else if objects.isObject value
                obj[key] = objects.cleanup value

        return obj

    ##
    ##
    ##
    isArray: (obj)->
        obj && !objects.isBuffer(obj) && (obj instanceof Array || (obj && obj.push && obj.pop && obj.length isnt undefined))

    ##
    ##
    ##
    isObject: (obj)->
        obj && !objects.isBuffer(obj) && typeof obj is 'object' && !objects.isArray(obj) && !objects.isDate(obj) && !objects.isRegExp(obj)

    ##
    ##
    ##
    isBuffer: (obj)->
        typeof Buffer isnt 'undefined' && obj instanceof Buffer

    ##
    ##
    ##
    isRegExp: (obj)->
        obj && obj instanceof RegExp

    ##
    ##
    ##
    isDate: (obj)->
        obj && obj instanceof Date

    ##
    ##
    ##
    isString: (obj)->
        obj && typeof obj is 'string'

    ##
    ##
    ##
    isNumber: (obj)->
        obj && typeof obj is 'number'

    ##
    ##
    ##
    isFunction: (obj)->
        obj && typeof obj is 'function'

    ##
    ##
    ##
    isEmpty: (obj)->
        return true if !obj

        if objects.isArray(obj) || objects.isString(obj)
            return !obj.length

        else if objects.isObject(obj)
            return !objects.keys(obj).length



    ##
    ##
    ##
    type: (obj)->

        if (type = typeof obj) is 'object'
            objects.isArray(obj) && type = 'array'
            objects.isRegExp(obj) && type = 'regexp'
            objects.isDate(obj) && type = 'date'

        return type



    ##
    ## TODOs
    ##
    traverse: (obj, handler, indent=0)->

        all = []

        ##
        _handle = (key, value)->
            if key && floyd.tools.objects.isObject(value) && all.indexOf(value) != -1
                #console.log key, value
                return '[Circular '+value.toString()+' ]'

            type = objects.type value

            if handler[type]
                value = handler[type] key, value

            else if handler.handle
                value = handler.handle type, key, value

            if type is 'object'
                all.push value

            return value

        ##
        JSON.stringify obj, _handle, indent


    ##
    ## experimental!
    ##
    delta: (data, defaults)->
        return data if !defaults
        return defaults if !data

        if objects.isArray data
            delta = []
            for i in [0..data.length-1]
                if val = objects.delta data[i], defaults[i]
                    delta.push val

        else if objects.isObject data
            delta = {}
            for key, v of data
                if val = objects.delta data[key], defaults[key]
                    delta[key] = val

        else if data isnt defaults
            delta = data

        return delta


    ##
    ##
    ##
    serialize: (obj, indent)->

        list = []

        ##
        model = floyd.tools.objects.traverse obj,

            function: (key, value)->
                code = value.toString()
                if !indent
                    code = code.replace(/[ ]{2,}/g, '').replace(/[\n]/g, '')
                list.push [ (_id='__FN'+list.length+'NF__'), code ]
                return _id

        , indent

        ##
        while list.length
            [id, code] = list.pop()
            model = model.replace '"'+id+'"', code

        ##
        return model


    ##
    ##
    ##
    immutable: (target, key, value)->
        objects.property target, key, value,
            get: (-> value)
            set: (-> value)


    ##
    ##
    ##
    property: (target, key, value, handler)->
        try

            target[key] = null
            Object.defineProperty target, key,

                get: ()=>
                    if handler.get then handler.get() else value

                set: (val)=>
                    old = value
                    value = val

                    if handler.set
                        value = handler.set value

                    return old

        catch err
            ## for the sake of the f*ckin M$ IE`s lack of real properties
            ## i do a try-catch here and set the property insecure and unhandled...

            target[key] = if handler.get then handler.get() else value

            if !__IEWARNING && ( __IEWARNING = true )
                ## ... but not without warning
                console.warn 'insufficient Object.defineProperty... code and security breaks might be possible!'
                floyd.system.errors.push new Error 'insufficient Object.defineProperty in floyd.tools.objects.property'

    ##
    ##
    ##
    dump: (obj, indent=4)->
        floyd.tools.objects.traverse obj,

            function: (key, value)->
                (_val=value.toString()).substr 0, _val.indexOf(')')+1

        , indent

    ##
    ##
    ##
    inspect: (obj, opts)->
        util.inspect obj, opts

    ##
    ##
    ##
    copy: (obj, addon)->

        if objects.isArray obj
            _obj = []
            for value in obj
                _obj.push value

        else
            _obj = {}
            for key, value of obj
                _obj[key] = value

        if addon
            _obj = @extend _obj, addon

        _obj


    ##
    ## for the convinience of (multi-parent) cloning
    ##
    clone: (addons...)->
        if addons[0]
            addons.unshift {}
            return @extend.apply @, addons

    ##
    ##
    ##
    extend: (target, args...)->
        if !target
            target = {}

        if typeof target is 'string'
            args.unshift target
            target = {}

        for item in args

            if typeof item is 'string'
                item = @resolve(item)

            if typeof item is 'function'
                item.call target

            else
                #console.log 'extend', target, item
                _extend target, item

        return target
    ##
    ##
    ##
    resolve: (item, base, fallback)->

        if typeof item is 'string' && item.indexOf('/') != -1
            return require item

        if fallback is false
            list = [base]
        else
            list = [base, (floyd:floyd), floyd, floyd.tools, fallback]

        for base in list
            if (_item = _resolve item, base) || _item is false
                return _item

    ##
    ##
    ##
    find: (key, base, dfault)->

        if typeof (value = _resolve key, base) is 'undefined' || value is null
            value = dfault

        return value

    ##
    ##
    ##
    write: (key, value, base)->
        _obj = base
        _key = key.split '.'

        _id = _key.pop()

        while _key.length
            _obj = (_obj[_key.shift()]={})

        _obj[_id] = value

        return _obj


    ##
    ## replaces the method with a wrapper which calls the interceptor
    ## the interceptor gets passed all arguments plus the replaced super-method
    ###
      # 1. given some random api object method. This one is saying hello to you.
      test =
          helloMyNameIs: (name, fn)->

              fn null, 'Hello ' + name + '!'

      # 2. this intercepts the method by adding 'How are you feeling today?'
      floyd.tools.objects.intercept test, 'helloMyNameIs', (name, fn, helloMyNameIs)->

          helloMyNameIs name, (err, res)->
              return fn(err) if err
              fn null,  + ' How are you feeling today?'

      # 3. usage. this will display 'Hello Floyd! How are you feeling today?'
      test.helloMyNameIs 'Floyd', (err, res)->

          console.log res
    ###
    ##
    intercept: (obj, method, interceptor)->

        _super = obj[method]

        obj[method] = (args...)->

            args.push (args...)->

                _super.apply obj, args

            interceptor.apply obj, args

        obj[method]._super = _super

        return obj


    ##
    ## this is an coffeescript adaption of Object.identical by Chris O'Brien
    ###
        Original script title: "Object.identical.js"; version 1.12
        Copyright (c) 2011, Chris O'Brien, prettycode.org
        http://github.com/prettycode/Object.identical.js

        Permission is hereby granted for unrestricted use, modification, and redistribution of this
        script, only under the condition that this code comment is kept wholly complete, appearing
        directly above the script's code body, in all original or modified non-minified representations
    ###
    ##
    identical: (a, b, sortArrays)->

        sort = (obj)->

            if sortArrays && floyd.tools.objects.isArray obj
                return obj.sort()

            else if typeof obj isnt 'object' || obj is null
                return obj

            result = []

            for key in floyd.tools.objects.keys(obj).sort()
                result.push
                    key: key
                    value: sort obj[key]

            return result

        return JSON.stringify(sort a) is JSON.stringify(sort b)

    ##
    ##
    ##
    stream2Buffer: (stream, fn)->
        data = []
        length = 0

        stream.on 'data', (chunk)->
            length += chunk.length
            data.push chunk

        stream.on 'error', fn

        stream.on 'end', ()->
            fn null, Buffer.concat(data, length), stream

    ##
    ##
    ##
    argsLoggingCallback: (fn, logger)->
        logger ?= console
        return (args...)->

            for arg in args
                logger.log arg
            fn.apply null, args

    ##
    ##
    ##
    map: (data, map, commands)->
        strings = floyd.tools.strings

        commands = objects.extend
            split: (chars, value)->
                return objects.resolve(value, data)?.split chars

            join: (chars, list)->
                if typeof list is 'string'
                    list = objects.resolve list, data

                else
                    for i in [0..list.length-1]
                        list[i] = objects.resolve list[i], data

                return list.join? chars

            format: (format, args)->
                if typeof args is 'string'
                    args = objects.resolve args, data

                for i in [0..args.length-1]
                    format = strings.replaceAll format, '$'+i, args[i]
                    args[i] = objects.resolve args[i], data

                return strings.format format, args

        , commands

        if objects.isArray map
            out = []
            for _key in map
                out.push objects.resolve _key, data
        else
            out = {}
            for key, sub of map
                if key.charAt(0) is '$' && cmd = commands[key.substr 1]
                    if objects.isArray sub
                        out = []
                        for value in sub
                            out.push cmd value, data, commands
                        return out

                    else if typeof sub is 'object'
                        for chars, value of sub
                            return cmd chars, value, data, commands

                    else
                        return cmd sub, data, commands

                else if typeof sub is 'string'
                    out[key] = objects.resolve sub, data

                else if objects.isArray sub
                    out[key] = []
                    for _key in sub
                        out[key].push objects.resolve _key, data

                else
                    out[key] = objects.map data, sub, commands

        return out


##
##
##
_resolve = (item, base)->
    #console.log 'resolve', item
    return if !base

    if (i=item.indexOf '.') > -1
        child = item.substr 0, i
        id = item.substr i + 1

        #console.log 'base:', child, 'child:', id, base

        index = -1
        if match = child.match /(.*)[\[]([0-9]+)[\]]/
            child = match[1]
            index = parseInt match[2]

        if base[child]
            #console.log 'searching', child, 'for', id, index

            _child = base[child]
            if index > -1
                _child = _child[index]

            _resolve id, _child


    else
        index = -1
        if match = item.match /(.*)[\[]([0-9]+)[\]]/
            item = match[1]
            index = parseInt match[2]

        _item = base[item]

        if index > -1
            #console.log id, typeof _item
            _item = _item[index]

        return _item

##
## private static helper to recursively merge objects
##
_extend = (target, source)->

    if !objects.isArray(target) && objects.isArray(source)
        for _source in source
            _extend target, _source

    else if objects.isArray source

        objects.process source,
            each: (item, next)->

                if objects.isObject(item)

                    value = null
                    if item.id
                        for _item in target
                            if item.id is _item.id
                                value = _item
                                break;

                    if !value
                        value = if objects.isArray(item) then [] else {}
                        target.push value

                    _extend value, item

                else if objects.isArray target
                    if target.indexOf(item) is -1
                        target.push item

                next()

    else
        objects.process source,
            each: (key, item, next)=>
                if objects.isObject(item) || objects.isArray(item)
                    if typeof target?[key] isnt typeof item
                        delete target[key]

                    if objects.isBuffer item
                        target[key] = item
                    else
                        target[key] ?= if objects.isArray(item) then [] else {}

                        _extend target[key], item

                else

                    target[key] = item

                next()

##
##
__IEWARNING = false
