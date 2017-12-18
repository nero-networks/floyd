
##
##
##
module.exports = (o, options, fn)->
    if typeof options is 'function'
        fn = options
        options = {}

    options = floyd.tools.objects.extend location,
        path: '/RpcServer'
    , options

    ## request the System.info for the API to proxy
    request options, 'System', 'info', [o], (err, res)=>
        return fn(err || new Error res.error) if err || res.error

        proxy = {} ## create the described proxy-methods
        for m in res.response.methods
            proxy[m.name] = buildMethod options, o, m.name

        fn null, proxy

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

        req.open 'POST', floyd.tools.strings.format '%s//%s%s',
            options.protocol, options.host, options.path

        req.send floyd.tools.strings.format 'o=%s&m=%s&a=%s',
            encodeURIComponent(o), encodeURIComponent(m), encodeURIComponent JSON.stringify a
