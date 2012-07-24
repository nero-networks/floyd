
module.exports =

    ##
    ## 
    ##
    class HttpCache extends floyd.http.Context 
            
        ##
        ##
        ##
        start: (done)->
            
            _storage = {__name: 'public'}
            
            @delegate '_addMiddleware', (req, res, next)=>
                
                if !@data.disabled
                    
                    if req.session.user
                        storage = req.session.HttpCacheStorage ?= {__name: 'private'}
                        
                    else
                        storage = _storage
                    
                    res.cache = req.cache = new @Handler req, res,
                        storage: storage
                        logger: @logger			
                
                next()
            
            super done


        ##
        ##
        ##
        Handler: 
        
            ##
            ##
            ##
            class Handler
                
                ##
                ##
                ##
                constructor: (@req, @res, cache)->
        
                    @_storage = cache.storage
                    
                    @_engines = []
                    
                    @logger = cache.logger
                    
                    ## intercept output... 
                    ## TODO send only for now
                    
                    _send = @res.send					
                    @_end = (body, headers, status)=>

                        @req.cache = @res.cache = null
                        
                        _send.apply @res, [body, headers, status]
                    
                    ##
                    ##
                    @res.send = _next = (body, headers={}, status)=>
                        if typeof headers is 'number' then status = headers; headers = {}
                        
                        if (status && status isnt 200) || @_engines.length == 0 			
                             
                            @_end body, headers, status
                            
                        else
                            @_engines.shift() body, headers, status, _next
                    
                    
                ##
                ##
                ##
                etag: ()->
                    
                    @_engines.push (body, headers, status, next)=>
                        
                        eTag = headers.ETag ?= 'E'+floyd.tools.strings.hash body
                            
                        if @req.headers['if-none-match'] is eTag
                            next null, headers, 304
                                
                        else
                            headers.ETag = eTag
                            
                            next body, headers, status
                        
                    return @
                
        
                ##
                ##
                ##
                expires: (date, create)->
                    ## fallback and do nothing if the given date-value is undefined
                    if !date
                        @logger.finer 'continue request uncached'
                        return create() 
                
                    now = new Date()
                    
                    ## allow seconds: treat as offset if less then current timestamp else as timestamp
                    if typeof date is 'number'
                        if date < +now
                            date += +now				
                        date = new Date date 
                    
                    url = @req.originalUrl || @req.url
                    
                    @logger.finer 'searching storage', @_storage.__name, date
                        
                    if data = @_storage[url]				
                        
                        if new Date(data.expires) > now					
                            
                            if (eTag = @req.headers['if-none-match']) && eTag is data.ETag
            
                                @logger.finest 'ETag responding with 304'
            
                                ## finish with 304
                                return @_end null, 304
                            
                            @logger.finest 'responding with cached data until', data.expires
                            
                            ## finish the request with cached contents
                            return @_end data.body,
                                'Content-Type': data.ctype
                                'Last-Modified': data.date
                                'Expires': data.expires
                                'ETag': data.ETag
                                
                    
                    @logger.finer 'register expires storage engine'
                    
                    ## register storage engine for later use
                    @_engines.push (body, headers, status, next)=>
                        
                        @logger.fine 'caching %s until %s', url, date
                        
                        @_storage[url] = 
                            
                            date: now
                            
                            expires: date
                            
                            body: body
                            
                            ctype: @res.ctype
                            
                            ETag: headers.ETag ?= 'E'+floyd.tools.strings.hash body
                        
                        next body, headers, status
                    
                    ## carry on with the request
                    create()
                
                    
                
                
                ##
                ##
                ##
                lastModified: (date, create)->
                    
                    #console.log 'check', date , @req.headers['if-modified-since'], date && date.toString() is @req.headers['if-modified-since']
                    
                    if date && date.toString() is @req.headers['if-modified-since']
                        #console.log 'res 304', date , @req.headers['if-modified-since']
                    
                        return @_end null, 304
                    
                    @_engines.push (body, headers, status, next)=>
                    
                        #console.log 'next create', date , @req.headers['if-modified-since']
                        
                        headers['Last-Modified'] = date
                        
                        next body, headers, status
                        
                    create()
                
            