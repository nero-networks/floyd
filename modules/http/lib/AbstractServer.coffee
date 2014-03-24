
module.exports = 

    ##
    ## A Floyd-Webserver 
    ##
    ## Implements an abstract base for a Floyd HTTP-Server Context
    ## the server-socket-communication feature needs to be implemented per platform
    ## take a look at ../platforms/node/lib/Server.coffee for the node implementation
    ## 
    class AbstractHttpServer extends floyd.http.Context
        
        constructor: (parent)->
            super parent
            
            @_hiddenKeys.push 'server'
        
        
        ##
        ## 
        ## @override
        configure: (config)->
        
            super new floyd.Config
                data:
                
                    ## the tcp-port to listen on for requests. 
                    ## data.host may be set in addition to a port-number
                    ## port may also contain the name of a unix-domain socket to listen on
                    port: 9030

                    ## the base route for children routing
                    route: '/.*'
                    
                    ## the Content-Type used as fallback for mime.lookup
                    ctype: 'text/html'
                    
                    ## a directory relative to floyd.appdir
                    public: ['./public']
                    
                    ## the default index file
                    index: 'index.html'
                
                
                ##
                children: [
                
                    id: 'sessions'
                    
                    type: 'http.sessions.Sessions'
                    
                    data: config?.data?.sessions || {}
                    
                ,			
                        
                    id: 'cache'

                    type: 'http.Cache'
                    
                    data: floyd.tools.objects.extend 
                        permissions: false
                    , config?.data?.cache
                    
                ,			
                        
                    id: 'users'

                    type: 'stores.Context'
                    
                    data: floyd.tools.objects.extend 
                        permissions: false
                    , config?.data?.users
                    
                ]
                
                
            , config
        
        
        boot: (done)->
            
            ##
            @server = @_createServer (req, res)=>
            
                ##
                @_handleRequest req, res, (err)=>
                    
                    ##
                    @_handleError req, res, err
            
            ##
            @server.use ?= (mw)=>
            
                @_addMiddleware mw
            
            ## call super to boot the actual floyd.Context instance
            super (err)=>
                return done(err) if err
                
                ## bind to tcp-port
                @server.listen @data.port, @data.host
                
                
                
                ## log a small "i'm alive" message
                @logger.info '%s is now listening on %s:%s', @_loginfo(), (@data.host||''), @data.port
        
                @_emit 'listening', @data.port, @data.host
                
                done()
        
        ##
        ##
        ##
        stop: (done)->
            @server.close done
            
        
        ##
        _loginfo:()->
            
            data = []
            for p in @data.public
                data.push p.replace floyd.system.libdir, 'floyd:'
                
            return data
            
        ##
        ##
        ##
        _createServer: (handler)->
            throw new floyd.error.NotImplemented 'http.AbstractServer._createServer'

        
        
        ##
        ##
        ##
        _prepareRequest: (req, res, done)->
            
            ##
            req.uri = req.url.split('?').shift()
            
            ##
            if @data.vhosts
                _ex = @data.vhosts._exclude
                _uri = req.uri
                if !@data.vhosts._exclude || (_ex.indexOf(_uri) is -1 && _ex.indexOf(_uri.substr 0, _uri.lastIndexOf('/')+1) is -1)
                    
                    hostname = req.headers.host
                    for vhost, prefix of @data.vhosts
                        if hostname.substr(0, vhost.length) is vhost
                            req.uri = prefix + req.uri
                            req.url = prefix + req.url
                            req.vhostpath = prefix
                        
            #console.log req.headers.host, req.uri
            
            ## 
            ## send handler
            res.send = (content, headers={}, code)=>

                @_send req, res, content, headers, code
            
            ##
            ## redirect handler sends a 302
            req.redirect = res.redirect = (uri, msg='moved to '+uri+'\n', code=302)=>
                
                if uri is 'back'
                    uri = req.headers.referer
                
                res.setHeader 'location', uri
                res.ctype = 'text/plain'
                res.send msg, code
            
            super req, res, done
                
        
        
        ##
        ##
        ##
        _send: (req, res, content, headers, code)->
                        
            if typeof headers is 'number'
                [code, headers] = [headers, code]
            
            for key, val of headers
                res.setHeader key, val

            res.writeHead (code||res.code||200), 'Content-Type': (res.ctype||@data.ctype)							
            
            if content && req.method isnt 'HEAD' && code isnt 304
                res.write content

            res.end()
            
        
        ##
        ##
        ##
        _handleError: (req, res, err)->
            if !res.err
                if err.status is 302
                    return req.redirect err.message
                        
                res.ctype = 'text/plain'
                res.code = err.status
            
                @_send req, res, err.message+'\n'
            
                res.err = err
            else
                @logger.error err 
