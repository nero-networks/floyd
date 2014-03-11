
http = require 'http'
url = require 'url'

qs = require 'querystring'

module.exports = tools = 

    ##
    ##
    Agent: http.Agent
           
    ##
    ##
    request: ()->
        http.request.apply http, arguments

    
    ##
    ##
    get: (options, fn)->
        
        tools.parseOptions options, (err, options)->
            
            http.get options, (res)->
                
                tools.readResponse res, fn		
    
    ##
    ##
    post: (options, data, fn)->
        
        data = qs.stringify data
        
        tools.parseOptions options, (err, options)->
            
            options.method ?= 'POST'
            options.headers ?= {}
            options.headers['Content-Type'] = 'application/x-www-form-urlencoded'
            options.headers['Content-Length'] = data.length
            
            #console.log options
            
            req = http.request options, (res)->
                
                tools.readResponse res, fn
                
            req.write data
            
    ##
    ##
    parseOptions: (options, fn)->
        
        if typeof options is 'string'
            options =
                url: options
        
        if options.url
            #console.log url.parse options.url
            {auth, hostname, port, path} = url.parse options.url
            if auth
                options.auth = auth
            options.host = hostname
            options.port = port
            options.path = path
            
        fn null, options


    ##
    ##
    parseData: (req, fn)->
        
        fn ?= (err, data)->
            return data
        
        if req.body 
            return fn null, req.body
        
        if typeof req is 'string'
            return fn null, qs.parse req
        
        data = req.url.split('?')[1] || ''
        
        if req.method is 'POST'
            data += '&' if data.length
            
            req.on 'data', (chunk)=> 
                data += chunk if chunk
            
        req.on 'end', ()=>
            fn null, req.body = qs.parse data
            
    
    ##
    ##
    readResponse: (res, fn)->
        data = ''           
            
        res.on 'data', (chunk)->
            data += chunk
            
        res.on 'end', ()->
            fn null, data, res
                
        res.on 'error', fn
    