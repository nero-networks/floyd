
##
##
##
Proxy = (o, options, fn)->
    if typeof options is 'function'
        fn = options
        options = {}

    if typeof options is 'string'
        options =
            url: options

    options = _extend
        path: '/RpcServer'
    , location, options

    proxy = {} ## create the described proxy-methods

    ## request the System.info for the API to proxy
    request options, 'System', 'info', [o], (err, res)=>
        return fn(err || new Error res.error) if err || res.error

        for m in res.response.methods
            proxy[m.name] = buildMethod options, o, m.name

        fn? null, proxy

    return proxy

_extend = (target, srclist...)->
    for src in srclist
        for key, val of src
            target[key] = val
    return target
    
##
## returns a function that is doing the rpc call
##
buildMethod = (options, o, m)->
    if options.buildMethod
        options.buildMethod options, o, m
    else
        return (a..., fn)->
            request options, o, m, a, (err, res)=>
                return fn(err) if err

                fn null, res.response


##
## doing the actual http request for the rpc call
##
request = (options, o, m, a, fn)->
    if options.request
        options.request options, o, m, a, fn

    else
        req = new XMLHttpRequest()

        req.addEventListener 'load', ()->
            if req.status is 200
                return fn null, JSON.parse req.responseText
            fn new Error req.status+' '+req.responseText

        req.open 'POST', options.url || "#{options.protocol}//#{options.host}#{options.path}"

        req.send "o=#{encodeURIComponent(o)}&m=#{encodeURIComponent(m)}&a=#{encodeURIComponent JSON.stringify a}"


module?.exports = Proxy

window?.OMARpc =
    createProxy: Proxy
