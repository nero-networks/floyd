
coffee = require 'coffee-script'
browserify = require 'browserify'

__PACKAGE =  'require.define("floyd", function (require, module, exports, __dirname, __filename)'
__PACKAGE += ' {var __modules = {};%svar floyd = {system:{version:"%s"},AbstractPlatform: __modules["floyd.AbstractPlatform"]()};'
__PACKAGE += ' module.exports = floyd = new (__modules["floyd.Platform"]())(floyd);floyd.boot(__modules);});\n'

__MODULE =   '__modules["%s"] = function %s() {var exports, module = {exports:exports={}};%s;return module.exports;};'
__INCLUDE =  'module.exports = (function() {%s})();\n'
__CLOSURE =  '(function() {%s})();\n'

module.exports =
    
    ##
    ##
    ## @platform node
    class HttpLibLoader extends floyd.http.Context
        
        ##
        ##
        ## @override
        configure: (config)->
            super new floyd.Config
                
                data:
                    ctype:			'application/javascript'
                    route:			'^/floyd.js'
                    
                    includes: 		{}
                    prepend:		[]
                    append:			[]
                    
                    modules:		['crypto']
                    
                    node_modules:	['path', 'events', 'http', 'url', 'floyd/node_modules/sprintf', 'floyd/node_modules/sanitizer', 'floyd/node_modules/dateformatjs']
                    
                    aliases: 		
                        sprintf: '/node_modules/floyd/node_modules/sprintf'
                        sanitizer: '/node_modules/floyd/node_modules/sanitizer'
                        dateformatjs: '/node_modules/floyd/node_modules/dateformatjs'
                        
                                        
            , config

        ##
        ##
        ##
        constructor: (config, parent)->
            super config, parent				
            
            debug = @data.find('debug')
            
            ## set the uglify-js minifier as the default filter except for debug mode
            @data.filter ?= (if !debug then 'uglify-js' else '')
            
            @_started = new Date().toString()
            
        ##
        ##
        ##
        start: (done)->
            super done
            
            if !@data.find('debug')
                process.nextTick ()=>
                    @_getCached (err)=>
                        @logger.error(err) if err
            
        ##
        ##
        ##
        _handleRequest: (req, res, next)->					
            
            res.ctype = @data.ctype
            
            req.cache.lastModified @_started, ()=>
            
                @_getCached (err, data)=>
                    return next(err) if err
                                        
                    ## activate gzip compression
                    res.compress()
                                
                    res.send data
                
        ##
        ##
        ##
        _getCached: (fn)->
        
            ## prepare the memory cache for the compiled result
            @__cache ?= 
                waiting: []
                init: false

            if @__cache.data
                ## return the cached data immediately... 
                fn null, @__cache.data
                
            else
                
                ## register incomming requests for async delivery
                @__cache.waiting.push fn
                
                ## only the first request will trigger the compiler run				
                if !@__cache.init && ( @__cache.init = true ) # --> equals false once then never again
                    try
                        @_compile (err, lib)=>
                            
                            ## populate @__cache.data to be delivered
                            ## to future requests from now on... (runtime-memcached)
                            @__cache.data = lib
                            
                            ## process waiting requests (includes at least our own res object)
                            while @__cache.waiting.length
                                @__cache.waiting.pop() null, lib
                                
                    catch err
                        fn err
        
            
            
                    
        ##
        ##
        ##
        _compile: (fn)->
            
            debug = @data.find 'debug'
            
            if @data.filter
                filter = require @data.filter
            
            ## reads file content and compiles coffee-script on-the-fly
            ##
            __read__ = (path)->
                
                _file = floyd.tools.files.fs.readFileSync(path, 'utf-8')
                
                if (_type = path.split('.').pop()) is 'coffee'
                    _file = coffee.compile _file, 
                        filename: path
                
                return _file
            
            

            ## build browserify
            
            handler = browserify
                filter: filter
                path: process.env.NODE_PATH
                cache: floyd.tools.files.tmp 'browserify.cache'
            
            ##
            ## include node_modules			
            for module in @data.node_modules
                
                handler.require module
                                                
            ##
            ## include non-node modules
            
            for name, file of @data.includes			
                #console.log 'include file %s as "%s"', file, name
                
                try
                    handler.include null, name, floyd.tools.strings.sprintf __INCLUDE, __read__(file) 
                
                catch e
                    console.error 'lib include error', e

            ##
            ## aliases
            
            for alias, module of @data.aliases
            
                handler.include null, alias, 'module.exports = require("'+module+'")'
            
            ##
            ##
            bundle = floyd.tools.strings.sprintf '/*!\n * floyd %s | (c) 2012 - https://github.com/nero-networks/floyd/LICENSE | compiled on %s\n */\n', floyd.system.version, new Date()
            
            ##
            ## prepend unprocessed files 
            ##
            for file in @data.prepend
                if debug
                    bundle += '\n/* ' + file + ' */\n'
                    
                bundle += __read__(file) + '\n'
            
            if debug
                bundle += '\n/* floyd lib - browserify bundle */\n\n'
            
            bundle += handler.bundle() + '\n'
            

            ## build floyd-satellite-lib
            
            ##
            _code = ''

            ##
            floyd.tools.libloader [floyd.system.libdir, floyd.system.appdir], {},
                platform: 'remote'
                modules: @data.modules
                
                ##
                module: _module = (target, name, path, pkg)=>
                    
                    try
                        _file = __read__(require.resolve path)

                        if filter
                            _file = filter _file
                        else
                            _file = '\n' + _file + '\n'
                        
                        _code += floyd.tools.strings.sprintf __MODULE, pkg, name, _file, pkg
                            
                    catch e
                        if !e.message.match 'Cannot find module' # e.code isnt 'MODULE_NOT_FOUND' ## > node 0.7
                            console.error 'lib build error', e
                            
                ##
                package: _module				
                    

            ##
            
            _code = floyd.tools.strings.sprintf __PACKAGE, _code, floyd.system.version
            
            ##		
            if debug
                bundle += '\n/* floyd core */\n'
                
            bundle += _code

            ##
            ## append unprocessed files 
            ##
            for file in @data.append
                if debug
                    bundle += '\n/* ' + file + ' */\n'
                    
                bundle += __read__(file) + '\n'
            
            ##
            fn null, bundle

