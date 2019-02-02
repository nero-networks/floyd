
module.exports =


    ##
    ##
    ##
    context: (id, type, config)->
        if typeof type is 'object' && !config
            config = type
            type = config.type

        new floyd.Config
            id: id

            type: 'stores.Context'

            data:
                type: type
                name: id

        , config



    ##
    ##
    ##
    read: (key, file='.floyd/default-store.json')->
        if !_CACHE[file] && floyd.tools.files.exists file
            _CACHE[file] = JSON.parse floyd.tools.files.read file

        floyd.tools.objects.resolve key, _CACHE[file] || {}


    ##
    ##
    ##
    write: (key, value, file='.floyd/default-store.json')->
        _data = data = _CACHE[file] || {}

        keys = key.split '.'
        while keys.length > 1 && _data[keys[0]]
            _data = _data[keys.shift()]

        _data[keys.shift()] = value

        floyd.tools.files.write file, JSON.stringify data, null, 4

_CACHE = {}
