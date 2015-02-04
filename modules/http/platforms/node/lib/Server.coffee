
## 
mime = require 'mime'

##
Cookies = require 'cookies'

module.exports = 

    ##
    ## A Floyd-Webserver 
    ##
    ## Implements a nodeish _createServer method for the Floyd HTTP-Server Context
    ##
    ## @platform node
    class NodeHttpServer extends floyd.http.AbstractServer
        
        ##
        ##
        ## @override
        configure: (config)->
            config = super new floyd.Config
            
                data:
                    module: 'http'
                    compression: true
                    
                    authManager: 'sessions'
                    
                children: [
                
                    id: 'sessions'
                    
                    data:
                        registry:
                            type: 'http.sessions.PersisedRegistry'
                    
                ,
                
                    id: 'lib'
                    
                    type: 'http.LibLoader'
                    
                    data: config?.data?.lib || {}
                    
                ]
            
            , config
            
            ## require the module instance with the configured module
            if typeof (@_module = config.data.module) is 'string'
                @_module = require @_module
                
            #console.log config.children
            return config
            
        
        ##
        ##
        ## @override
        _createServer: (handler)->
                
            @_module.createServer(handler)
                
        ##
        ##
        ##
        _prepareRequest: (req, res, next)->
            
            ##
            ## there is a sneaky gzip module created in 2010 by TJ @Sencha
            ## i adapted it to use the node zlib module for gzip
            ## it still needs review in case of deflate management
            ##								
            __GZIP = require('../gzip')()
            
            req.compress = res.compress = ()=>
                #console.log 'compression ordered'
                
                if @data.compression && !res.__compressed
                    #console.log 'compression accepted'
                    
                    __GZIP req, res, (err)->
                        #console.log 'compression applyed', req.url
                        
                        res.__compressed = true
                        return next(err) if err
                        
            ##
            ## cookies
            ##
            req.cookies = res.cookies = new Cookies req, res
            
            super req, res, next
            

        ##
        ##
        ##
        _createContent: (req, res, next)->
            super req, res, (err, content)=>
                return next(err, content) if err or content
                
                ## load file only if no content until here
                
                floyd.tools.http.files.resolve decodeURIComponent(req.url), @data.public, (err, file)=>
                    return next(err) if err
                    
                    files = floyd.tools.files
                    
                    ## if file is a directory add the default index file
                    if files.fs.lstatSync(file).isDirectory()
                    
                        ## the browser thinks of a file if the trailing slash is omittet
                        ## so we send a redirect back to the browser just to add this slash
                        ## ugly but hopeless... we must ensure the browser sees a directory
                        
                        url = req.url.split '?'
                        path = url.shift()
                        if params = url.join '?'
                            params = '?'+params
                        
                        #console.log path, url, params
                        if floyd.tools.strings.tail(path) isnt '/'
                            return res.redirect path+'/'+params
                        
                        
                        ## refuse the access permission if there is no index file		
                        else if !files.fs.existsSync (file = files.path.join file, @data.index)
                    
                            return next new floyd.error.Forbidden req.url
                    
                    
                    ## INVESTIGATE dunno why, but i have to read it again to get the correct inode ?!?
                    ## even if its not a directory...
                    stats = files.fs.lstatSync file
                    
                    res.setHeader 'Last-Modified', stats.mtime.toUTCString()
                    
                    ## lookup the mimetype of the requested file
                    res.ctype = mime.lookup(file)||@data.ctype
                    
                    if (_last = req.headers['if-modified-since']) && _last is stats.mtime.toUTCString()
                    
                        res.send '', 304 
                    
                    else
                        ##
                        ## EXPERIMENTAL enable streaming for native files
                        ## bypass the send method here :-(
                        res.setHeader 'Content-Length', stats.size
                        res.writeHead 200, 'Content-Type': res.ctype
                        
                        files.fs.createReadStream(file).pipe res
        
                        

                        # res.cache?.etag()
                        
                        ##
                        ## still here? let's read the files content
                        ##				
    
                        #files.fs.readFile file, (e, data)=>
                        #    err = e
                        #    
                        #    if data.length > 512
                        #        res.compress()
                        #                                    
                        #    ## send and finish response
                        #    next null, data
                        
    
    