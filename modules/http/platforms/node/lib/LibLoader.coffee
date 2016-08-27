
coffee = require 'coffee-script'
browserify = require 'browserify'

__PACKAGE =  '''
/* floyd core */
var __modules = {};

%s

var floyd = {
    system:{
        version:"%s"
    },
    AbstractPlatform: __modules["floyd.AbstractPlatform"]()
};

module.exports = floyd = new (__modules["floyd.Platform"]())(floyd);

floyd.boot(__modules);
'''

__MODULE =   '''    __modules["%s"] = function() {
    var exports, module = { exports: exports={} };

%s;

    return module.exports;
};'''

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

                    modules:		[]

                    node_modules:	['url', 'floyd/node_modules/sprintf']

                    aliases:
                        sprintf: '/node_modules/floyd/node_modules/sprintf'

            , config

        ##
        ##
        ##
        init: (config, done)->
            super config, (err)=>
                return done(err) if err

                @_started = new Date()

                done()

        ##
        ##
        ##
        start: (done)->
            super done

            if !@data.find('debug')
                setImmediate ()=>
                    @getCompiledCode (err)=>
                        if err
                            @logger.info 'Error while precompiling floyd browser lib'
                            @logger.error(err)

        ##
        ##
        ##
        _handleRequest: (req, res, next)->

            res.ctype = @data.ctype
            req.cache.lastModified @_started, ()=>

                @getCompiledCode (err, data)=>
                    if err
                        @logger.info 'Error while compiling floyd browser lib'
                        @logger.error err
                        return next(err)

                    ## activate gzip compression
                    res.compress()

                    res.send data

        ##
        ##
        ##
        getCompiledCode: (fn)->

            ## prepare the memory cache for the compiled result
            @__cache ?=
                waiting: []
                init: false

            if @__cache.data
                ## return the cached data immediately...
                fn null, @__cache.data

            else if @__cache.error
                fn @__cache.error

            else

                ## register incomming requests for async delivery
                @__cache.waiting.push fn

                ## only the first request will trigger the compiler run
                if !@__cache.init && ( @__cache.init = true ) # --> equals false once then never again
                    try
                        @_compile (err, lib)=>
                            if err
                                @__cache.error = err
                                return fn(err)

                            ## populate @__cache.data to be delivered
                            ## to future requests from now on... (runtime-memcached)
                            @__cache.data = lib

                            ## process waiting requests (includes at least our own res object)
                            while @__cache.waiting.length
                                @__cache.waiting.pop() null, lib

                    catch err
                        console.log 'compile error'
                        fn err




        ##
        ##
        ##
        _compile: (fn)->

            debug = @data.find 'debug'

            ## reads file content and compiles coffee-script on-the-fly
            ##
            __read__ = (path)->

                _file = floyd.tools.files.fs.readFileSync(path, 'utf-8')

                if (_type = path.split('.').pop()) is 'coffee'
                    _file = coffee.compile _file,
                        filename: path

                return _file



            ##
            bundle = floyd.tools.strings.sprintf '/*!\n * floyd %s | (c) 2012 - https://github.com/nero-networks/floyd/LICENSE | compiled on %s\n */\n', floyd.system.version, new Date()

            bundle += '\nvar __initTime__;\n'

            ##
            ## prepend unprocessed files
            ##
            for file in @data.prepend
                if debug
                    bundle += '\n/* ' + file + ' */\n'

                bundle += 'try {\n'+__read__(file) + '\n} catch(e) {'+(if @data.showErrors then 'console.error(e);' else '')+'};\n'

            if debug
                bundle += '\n/* floyd lib - browserify bundle */\n\n'


            ## build browserify

            handler = browserify
                path: process.env.NODE_PATH
                cache: floyd.tools.files.tmp 'browserify.cache'

            ##
            ## include node_modules
            for module in @data.node_modules
                try
                    handler.require module,
                        expose: module
                catch err
                    return fn err

            ##
            ## include non-node modules
            for name, file of @data.includes
                try
                    handler.require file,
                        expose: name
                catch err
                    return fn err

            @_buildFloyd __read__, (err, tmpfile)=>
                try
                    handler.require tmpfile,
                        expose: 'floyd'
                catch err
                    return fn err

                handler.bundle (err, lib)=>
                    return fn(err) if err

                    bundle += lib + '\n'

                    ##
                    ## append unprocessed files
                    ##
                    for file in @data.append
                        if debug
                            bundle += '\n/* ' + file + ' */\n'

                        bundle += 'try {\n'+__read__(file) + '\n} catch(e) {'+(if @data.showErrors then 'console.error(e);' else '')+'};\n'

                    ##
                    fn null, bundle

        ##
        ##
        ##
        _buildFloyd: (__read__, fn)->
            ## build floyd-satellite-lib

            ##
            _code = ''

            ##
            _dirs = [floyd.system.libdir, floyd.system.appdir]

            files = floyd.tools.files
            (parts = floyd.system.appdir.split '/').pop()
            path = parts.join '/'
            if files.fs.existsSync files.path.join path, 'modules'
                _dirs.push path

            floyd.tools.libloader _dirs, {},
                platform: 'remote'
                modules: @data.modules

                ##
                module: _module = (target, name, path, pkg)=>
                    try
                        _file = '\n' + __read__(require.resolve path) + '\n'

                        _code += floyd.tools.strings.sprintf __MODULE, pkg, _file

                    catch e
                        if !e.message.match 'Cannot find module' # e.code isnt 'MODULE_NOT_FOUND' ## > node 0.7
                            console.error 'lib build error', e.toString()

                ##
                package: _module


            ##

            _code = floyd.tools.strings.sprintf __PACKAGE, _code, floyd.system.version

            tmpfile = files.tmp('browser.js')
            files.write tmpfile, _code, (err)=>
                return fn(err) if err

                fn null, tmpfile
