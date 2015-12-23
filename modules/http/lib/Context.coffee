
module.exports = 

    ##
    ## A Floyd-Webserver  
    ##
    ## Implements an abstract middleware-child class
    ## 
    class HttpContext extends floyd.Context
                
        ##
        ## @override
        configure: (config)->	
            config = super new floyd.Config
            
                data:
                    ctype: 'text/plain'
                    remote: true			
                    
            , config
            
            @_model = 
                remote: config.remote
                local: if config.remote then floyd.tools.objects.clone(config.remote, config.local) else null
            
            if !@_model.remote && @_model.local
                @_model.remote = {}
            
            
            if typeof (route = config.data.route) is 'function'
                config.data.route = ()=>
                    route.apply @, arguments
            
            @_content = config.content
            
            return config

            
        ##
        ##
        ##
        start: (done)->

            @_router = new floyd.http.Router @ID
        
            super (err)=>			
                done err

                ##				
                ##
                if !err 
                    
                    if @data.remote && @_model.remote
                    
                        ##
                        @_addRoute '/boot.js', (req, res, next)=>						
                            
                            @_createRemote req, res, (err, remote)=>
                                return next(err) if err || !remote
                                                                
                                if res.compress && remote.length > 512
                                    res.compress()
                            
                                res.send remote+'\n'
                
                        , false ## no delegation
                
                        
                    ##					
                    if @data.route
                        @delegate '_addRoute', @data.route, (req, res, next)=>
                        
                            req.uri = req.uri.replace @data.route, '/'
                            
                            @_handleRequest req, res, next
                


        ##
        ## TODO: connect.use has the signature route, handler
        ##
        _addMiddleware: (handlers...)->
            @_middleware ?= []
            
            #console.log 'adding middleware', handler
            for handler in handlers
                @_middleware.push handler
        
        
        ##
        ##
        ##
        _prepareRequest: (req, res, done)->
            
            ##
            if @data.rewrite 
            
                for expr, replacement of @data.rewrite
                    if !(expr instanceof RegExp)
                        expr = new RegExp expr
                                        
                    if expr.exec req.uri
                        
                        req.rewrittenUri = req.uri
                        req.rewrittenUrl = req.url
                        
                        _uri = req.uri.replace expr, replacement
                
                        req.url = req.url.replace new RegExp(req.uri+'(([?].*)?$)'), _uri+'$1'
                        
                        req.uri = _uri
            
            
            ##
            @_process @_middleware,
            
                each: (handler, next)=>
                    handler req, res, next
            
                done: done
        
        
        ##
        ##
        ##
        _handleRequest: (req, res, next)->
            
            #@logger.info 'prepare'
            
            @_prepareRequest req, res, (err)=>
                return next(err) if err 

                #@logger.info 'route'
                                
                @_router.handle req, res, (err)=>			
                    return next(err) if err
                    
                    #@logger.info 'create'
                    
                    @_createContent req, res, (err, content)=>
                        return next(err) if err
    
                        if content
                            if typeof content isnt 'string' && !(content instanceof Buffer)						
                                content = content.toString()
                            
                            res.ctype ?= @data.ctype
                            
                            if res.compress && content.length > 512
                                res.compress()								
                            
                            res.send content
                            
                        else
                            #@logger.info 'no content'
                    
                            next()
                        
                
        ##
        ##
        ##
        _createContent: (req, res, fn)->
            if @data.content
                @logger.warn 'config.data.content is deprecated! use config.content instead'
                
            if typeof (content = @_content) is 'function'
                content.apply @, [req, res, fn]
                
            else
                fn null, content
            
            
        ##
        ##
        ##
        _createRemote: (req, res, fn)->
            
            @_createModel req, res, 'remote', (err, model)=>
                return fn(err) if err
                
                @_createBoot req, res, model, (err, boot, model)=>
                    return fn(err) if err
                    
                    @_buildRemote req, res, boot, model, fn
                
                
        ##
        ##
        ##
        _createModel: (req, res, type, fn)->

            next = (err, model)=>
                return fn(err) if err
                
                #console.log 'model', req.session
                
                if model
                    model.id =  floyd.tools.strings.uuid()
                    
                    if @data.find 'authProxy'
                        
                        model.data ?= {} 
                        model.data.authManager ?= @data.find 'authManager'
                        
                        if @data.find 'debug'
                            model.data.debug = true
                        
                        _parent = @
                        while _parent.parent && !_parent.data.authProxy
                            _parent = _parent.parent

                        model.ORIGIN = _parent.id
                        
                        model.TOKEN = req.session.TOKEN
                        
                        #if req.session.user
                        #    model.USER = req.session.user

                fn null, model
            
            
            
            if typeof (model = @_model[type]) is 'function'
                model.apply @, [req, res, next]
                
            else if model
                next null, floyd.tools.objects.clone model
                
            else if !(@delegate '_createModel', req, res, type, next).success
                next()


        
        ##
        ## 
        ##
        _createLocalModel: (req, res, fn)-> ## DEPRECATED
            @logger.warning 'DEPRECATED: _createLocalModel\n\tuse @_createModel(req, res, \'local\', fn)'
            @_createModel req, res, 'local', fn
                
            
            
        ##
        ## 
        ##
        _createRemoteModel: (req, res, fn)-> ## DEPRECATED
            @logger.warning 'DEPRECATED: _createRemoteModel\n\tuse @_createModel(req, res, \'remote\', fn)'
            @_createModel req, res, 'remote', fn
        
        
        ##
        ##
        ##
        _createBoot: (req, res, model, fn)->					
            
            if !(boot = floyd.tools.objects.cut(model, '__boot__', __boot__))
                boot = __boot__
                
            boot = boot.toString()
            
            if !@data.find('debug') ## EXPERIMENTAL minify me; strip all double spaces and linefeeds
                boot = boot.replace(/[ ]{2,}/g, '').replace(/[\n]/g, '')
                        
            fn null, boot, model
        
        
        ##
        ##
        ##
        _buildRemote: (req, res, boot, model, fn)->
            return fn() if !model
        
            res.ctype ?= 'application/javascript'
            model = floyd.tools.objects.serialize model, (if @data.find('debug') then 4 else 0)
            
            fn null, "(#{boot})(#{model})"
            
        

        ##
        ##
        ##
        _addRoute: (route, handler, delegate=true)->
        
            if @data.route
                @_router.add route, handler
                
            else if delegate
                @delegate '_addRoute', route, handler
                
                
        


##
## remote code - gets serialized for browsers
##
                            
##
##
##
__boot__ = (config)->    
    
    ##    
    _INITIALIZED_ = false
    _TERMINATED_ = false
    ctx = null
    
    ##
    attachEvent = (event, listener)->
        if window.addEventListener
            window.addEventListener event, listener, false # real browsers
        else
            document.attachEvent 'on' + event, listener # IE quirks
            window.attachEvent 'on' + event, listener # IE8
            
    
    ##
    init = (e)->
        return undefined if _INITIALIZED_ 
        _INITIALIZED_= true

        window.floyd = require 'floyd'
        
        window.__initTime__ = +new Date()
        
        ctx = floyd.init config, (err)->
            return console.error(err) if err    

    attachEvent 'DOMContentLoaded', init
    attachEvent 'load', init
    
    ##        
    terminate = (e)->
        return undefined if _TERMINATED_
        _TERMINATED_ = true
        
        stopped = !ctx.stop
        destroyed = !ctx.destroy

        next = (err)->
            console.error(err.stack||err) if err

            if !stopped && stopped = true
                ctx.stop next
    
            else if !destroyed && destroyed = true
                ctx.destroy next

        next()
                
        return undefined
    
    attachEvent 'beforeunload', terminate
    attachEvent 'unload', terminate
    
    return undefined
              