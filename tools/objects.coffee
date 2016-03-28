
module.exports = objects =

    ##
    ##
    ##
    keys: (obj)->
        return (key for key of obj)


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

        _array = false

        _iter = []

        ##
        next = (err)->
            done(err) if err

            return done() if !_iter.length

            if _array
                each _iter.shift(), next

            else
                each (key=_iter.shift()), obj[key], next


        ##
        if floyd.tools.objects.isArray obj
            _array = true

            _iter.push item for item in obj

        else
            _iter.push key for key, val of obj

        ##
        next()


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

        _all = []

        ##
        _handle = (key, value)->
            if key && floyd.tools.objects.isObject(value) && _all.indexOf(value) != -1
                console.log key, value
                return '[Circular '+value.toString()+' ]'

            type = objects.type value

            if handler[type]
                value = handler[type] key, value

            else if handler.handle
                value = handler.handle type, key, value

            if type is 'object'
                _all.push value

            return value

        ##
        JSON.stringify obj, _handle, indent



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
_resolve = (item, base)->
    #console.log 'resolve', item
    return if !base

    if (_i=item.indexOf '.') > -1
        _child = item.substr 0, _i
        _id = item.substr _i + 1

        #console.log 'base:', _child, 'child:', _id, base

        if base[_child]
            #console.log 'searching', _child, 'for', _id

            _resolve _id, base[_child]

    else
        base[item]


##
## private static helper to recursively merge objects
##
_extend = (target, source)->

    if !objects.isArray(target) && objects.isArray(source)
        for _source in source
            _extend target, _source

    else if objects.isArray source

        for item in source

            if objects.isObject(item)

                value = null
                if item.id
                    for _item in target
                        if item.id is _item.id
                            value = _item
                            break;
                ## removed this to prevent element merging if id attribute is not present
                ##else
                ##    t_index ?= 0
                ##    if value = target[t_index++]
                ##
                ##        while value.id
                ##            value = target[t_index++]

                if !value
                    value = if objects.isArray(item) then [] else {}
                    target.push value

                _extend value, item

            else
                target.push item

    else

        for key, item of source
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

##
##
__IEWARNING = false
