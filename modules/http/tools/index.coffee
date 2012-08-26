
http = require 'http'
url = require 'url'

qs = require 'querystring'

module.exports = 

    ##
    ##
    Agent: http.Agent
    
    ##
    ##
    get: (options, fn)->
        if typeof options is 'string'
            {host, port, path} = url.parse options
            options =
                host: host
                port: port
                path: path
        
        if options.url
            {host, port, path} = url.parse options.url
            options.host = host
            options.port = port
            options.path = path
        
        #console.log options
        
        http.get options, (res)->			
            data = ''			
            
            res.on 'data', (chunk)->
                data += chunk
            
            res.on 'end', ()->
                fn null, data, res
                
            res.on 'error', fn
    
    ##
    ##
    request: ()->
        http.request.apply http, arguments

    ##
    ##
    parseData: (req, fn)->
        
        if req.body 
            return fn null, req.body
        
        if typeof req is 'string'
            fn null, qs.parse req
        
        data = req.url.split('?')[1] || ''
        
        if req.method is 'POST'
            data += '&' if data.length
            
            req.on 'data', (chunk)=> 
                data += chunk if chunk
            
        req.on 'end', ()=>
            fn null, req.body = qs.parse data
            
