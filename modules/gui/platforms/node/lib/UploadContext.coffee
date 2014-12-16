    
module.exports =

    class UploadContext extends floyd.Context
    
        configure: (config)->
            super new floyd.Config
                data:
                    route:'/upload'
                    
                    accept: '.*'
                    
                    maxSize: 0
                    
            , config
        
        ##  
        ##  
        ##  
        start: (done)->
            super (err)=>
                return done(err) if err
                
                @_registry = {}
                
                @parent._addRoute @data.route, (req, res, next)=>
                                        
                    if !(handler = @_registry[req.session.TOKEN])
                        @error err = new Error 'not registered'
                        return next err 
        
                    delete @_registry[req.session.TOKEN]
                    
                    handler.accept = @data.accept
                    handler.maxSize = @data.maxSize
                    
                    ##
                    floyd.tools.http.upload req, res, handler, (err, files, fields)=>                        
                        if err
                            handler.error err 
                            return next err
                        
                        res.send 'ok'
                        
                        handler.request = req
                        
                        @_handleUpload handler, files, fields, (err)=>
                            return handler.error(err) if err
                            
                            handler.disconnect()
                
                ##
                done()
                            
        
        ##
        ##
        ##
        registerUpload: (handler)->
            
            (handler.identity = @registerUpload.identity).token (err, token)=>
                
                @_registry[token] = handler
                                      
                handler.connect()
                
        ##  
        ##  
        ##  
        _handleUpload: (handler, files, fields, fn)->
            @_cleanup files, fn
            
        
        ##
        ##
        ##
        _cleanup: (files, fn)->
            @_process files,
                done: fn
                
                each: (file, next)=>
                    setImmediate ()=>
                        floyd.tools.files.rm file.path
                
                        next()

                    