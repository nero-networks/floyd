
http = require 'http'
url = require 'url'

qs = require 'querystring'
formidable = require 'formidable'

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
        
        else
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

    
    ##
    ##
    upload: (req, res, handler, done)->
    
        ##
        handler.data = data = 
            total: 0
            received: 0
            file: ''
    
        
        ## formidable - nothing more to say!
        
        
        ##
        form = formidable.IncomingForm()
                
        if handler.maxSize && parseInt(req.headers['content-length']) > handler.maxSize
            handler.error err = new Error 'limit exceeded'
            return done err
        
        form.uploadDir = floyd.system.appdir+'/.floyd/tmp/'
        
        curr = 0
        file = null
        sec = 0
        progress = ()=>    
            
            if handler.progress && data.total && data.file
                now = +new Date()
                data.progress = (parseInt data.received * 100 / data.total)
                
                if data.file isnt file || data.progress is 100 || data.progress >= curr + 5 || now > sec + 1000
                    
                    sec = now
                    curr = data.progress
                    file = data.file
                    
                    data.state = 'uploading'
                    
                    handler.progress data
     
     
        ## progress
        
        ##
        form.on 'fileBegin', (field, file)=>
    
            if file.type.toLowerCase().match handler.accept
                data.file = file.name
                
                progress()
            
            else                
                handler.error new Error 'invalid type:'+file.name
                
        
        ##
        form.on 'progress', (received, total)=>
            
            data.received = received
            data.total = total
            
            progress()
        
        
        ## collect files
        
        files = []
        
        ##
        form.on 'file', (field, file)=>
                
            if file.name is data.file
            
                files.push file
                
                if handler.file
                    handler.file 
                        name: file.name
                        size: file.size
                    , data, field
                
                progress()
            
        
        ## fire!
        
        ##
        form.parse req, (err, fields)=>            
            done err, files, fields
        
        
    