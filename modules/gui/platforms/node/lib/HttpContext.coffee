
vm = require 'vm'

##

module.exports =

    ##
    ##
    ##
    class GuiHttpContext extends floyd.http.Context


        ##
        ##
        ##
        configure: (config)->
            @_template ?= config.template
            @__POOL__ = []

            super new floyd.Config

                data:
                    ctype: 'text/html'

                    libloader: 'lib'
                    poolsize: 5

            ,config


        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err

                if @_model.remote
                    @_model.remote.data ?= {}
                    @_model.remote.data.origin = @ID

                if @_model.local
                    @_model.local.data ?= {}
                    @_model.local.data.origin = @ID

                @_createContext (err, ctx)=>
                    @_releaseContext(ctx) if ctx
                    done err

        ##
        ##
        ##
        _createContent: (req, res, fn)->
            super req, res, (err, content)=>
                return fn(err) if err

                res.cache?.etag()

                if !content

                    if @_template

                        (floyd.tools.gui.ck @_template)
                            format: @data.find('debug')
                            req: req
                            res: res
                            context: @

                        , (err, content)=>
                            return fn(err) if err

                            @_processContent req, res, content, fn


                    else if (_public = @data.find('public'))

                        url = @data.file || req.url.split('?').shift()

                        floyd.tools.http.files.resolve url, _public, (err, file)=>
                            return fn(err) if err

                            files = floyd.tools.files

                            if files.fs.lstatSync(file).isDirectory()
                                file = files.path.join file, @data.find 'index'

                            files.fs.readFile file, 'utf-8', (err, content)=>
                                return fn(err) if err


                                @_processContent req, res, content, fn

                else
                    @_processContent req, res, content, fn


        ##
        ##
        ##
        _processContent: (req, res, content, fn)->

            if @data.find 'no_processing'
                return fn null, content

            ##
            @_createModel req, res, 'local', (err, model)=>
                return fn(err) if err

                if !model
                    fn null, content

                else

                    model = floyd.tools.objects.serialize model, (if @data.find('debug') then 4 else 0)

                    if ( @data.engine || @data.find 'gui.engine', 'cheerio' ) is 'jsdom'

                        @_processContent_jsdom req, res, content, model, fn

                    else

                        ## cheerio is the default now...

                        @_processContent_cheerio req, res, content, model, fn










        ## ----------- cheerio ------------- ##


        ##
        ##
        ##
        _processContent_cheerio: (req, res, content, model, fn)->

            ##
            @_getContext (err, ctx)=>
                return fn(err) if err

                ##
                @_initContext req, res, ctx, (err)=>

                    ##
                    ctx.$ = require('cheerio').load content

                    ctx.__initTime__ = +new Date()

                    ##
                    _released = false
                    ctx.__done__ = (err, result)=>
                        if !_released && _released = true
                            @_releaseContext ctx

                        if err
                            fn err

                        else
                            fn null, result


                    ##
                    vm.runInContext "(#{__boot_cheerio__})(#{model})", ctx



        ##
        ##
        ##
        _createContext: (fn, _retry)->
            ##
            if !@__SCRIPT
                return @lookup @data.libloader, @identity, (err, ctx)=>
                    return done(err) if err
                    setImmediate ()=>
                        ctx.getCompiledCode (err, script)=>
                            return fn(err) if err

                            if _retry && !(@__SCRIPT = script)
                                return fn new Error 'libloader problem'

                            @_createContext fn, true

            ##
            ctx =
                window: {}
                console: console
                setTimeout: (args...)-> setTimeout.apply null, args
                clearTimeout: (args...)-> clearTimeout.apply null, args

            vm.createContext ctx

            try
                vm.runInContext @__SCRIPT+"\nvar floyd = require('floyd');", ctx
            catch err
                console.log 'error while cheerio floyd require', err

            ctx.floyd.system.platform = 'cheerio'
            ctx.floyd.system.os = floyd.system.os
            ctx.floyd.system.libdir = floyd.system.libdir
            ctx.floyd.system.appdir = floyd.system.appdir
            ctx.floyd.tools.files = floyd.tools.files

            ctx.floyd.__parent =
                lookup: (name, identity, fn)=>
                    @lookup name, identity, fn

            ##
            fn null, ctx


        ##
        ##
        ##
        _getContext: (fn)->

            if @__POOL__.length
                fn null, @__POOL__.pop()

            else
                @_createContext fn

        ##
        ##
        ##
        _releaseContext: (ctx)->

            persistentKeys = ['run', 'getGlobal', 'dispose', 'process', 'console', 'setTimeout', 'setImmediate', 'clearTimeout', 'clearImmediate', 'floyd', 'require', '_modules']

            if @__POOL__.length < @data.poolsize
                for key, value of ctx
                    if ctx[key] && persistentKeys.indexOf(key) is -1
                        vm.runInContext "delete "+key+";", ctx

                @__POOL__.push ctx

            else
                ctx.dispose()


        ##
        ##
        ##
        _initContext: (req, res, ctx, done)->

            ##
            url = (req.rewrittenUrl || req.url).substr (req.vhostpath||'').length
            ctx.location = require('url').parse 'http://'+req.headers.host+url

            ## fake the protocol while forwarded from https proxy
            if req.headers['x-forwarded-proto'] is 'https'
                ctx.location.protocol = 'https:'
                ctx.location.href = ctx.location.href.replace /^http\:/, 'https:'

            ##
            ctx.document =
                referer: req.referer
                cookie: 'FSID='+req.session.SID+'; path=/; httponly'

            ##
            ctx.window = ctx

            ctx.window.setImmediate = setImmediate
            ctx.window.clearImmediate = clearImmediate

            ##
            done()





        ## ------------ JSDOM -------------- ##



        ##
        ##
        ##
        _processContent_jsdom: (req, res, content, model, fn)->

            ##
            #start = +new Date()
            @_createWindow req, content, (err, window)=>
                return fn(err) if err

                #console.log 'create:', (+new Date()) - start

                ##
                window.addEventListener 'unload', next = ()=>
                    #console.log 'run:', (+new Date()) - start

                    window.removeEventListener 'unload', next

                    ## send the response
                    _dt = window.document._doctype?._fullDT || '<!DOCTYPE html>'
                    fn null, _dt+window.document.innerHTML

                    ## cleanup async!
                    process.nextTick ()=>

                        ## release the jsdom-window
                        @_releaseWindow window

                ##
                window.addEventListener 'error', onerr = (e)=>
                    window.removeEventListener 'unload', onerr

                    fn e.data

                    process.nextTick ()=>
                        @_releaseWindow window


                ## fire!
                window.run "(#{__boot_jsdom__})(#{model})"




        ##
        ##
        ##
        _createWindow: (req, template, fn)->

            ## TODO https
            prefix = 'http://'+req.headers.host

            ##
            require('jsdom').env

                html:template

                src: [@__SCRIPT]

                document:
                    referer: req.referer
                    cookie: 'FSID='+req.session.SID+'; path=/; httponly'

                done: (err, window)=>
                    return fn(err) if err

                    process.nextTick ()=>

                        window.$('html > script').remove()

                        _loc = req.url
                        if req.vhostpath
                            _loc = _loc.substr req.vhostpath.length

                        window.location = require('url').parse prefix+_loc

                        ## fake the protocol while forwarded from https proxy
                        if window.location.protocol is 'http:' && (proto = req.headers['x-forwarded-proto']) is 'https'
                            window.location.protocol = 'https:'
                            window.location.href = window.location.href.replace /^http\:/, 'https:'

                        window.console = console

                        window.floyd = window.require 'floyd'

                        process.nextTick ()=>

                            window.floyd.system.platform = 'jsdom'

                            window.floyd.system.libdir = floyd.system.libdir
                            window.floyd.system.appdir = floyd.system.appdir

                            window.floyd.tools.files = floyd.tools.files

                            window.floyd.__parent =
                                lookup: (name, identity, fn)=>
                                    @lookup name, identity, (err, ctx)=>
                                        fn err, ctx

                            fn null, window



        ##
        ##
        ##
        _releaseWindow: (window)->

            window.require = null
            window.floyd = null

            window.close()



##

##
## remote code - gets evaluated into the cheerio context
##
__boot_cheerio__ = (config)->

    floyd.init config, (err, ctx)=>
        return __done__(err) if err

        __done__ null, $.html()

        stopped = !ctx.stop
        destroyed = !ctx.destroy

        next = (err)->
            return console.error(err) if err

            if !stopped && stopped = true

                ctx.stop next

            else if !destroyed && destroyed = true

                ctx.destroy next

        next()



##
## remote code - gets serialized and evaluated into the jsdom window
##


__boot_jsdom__ = (config)->

    require 'path' ## hack to avoid error
    ## Object #<Object> has no method 'path'
    ## at Function.resolve (http://tesla:9080/floyd.js:45:36)

    trigger = (type, data)->
        (event = window.document.createEvent 'Event').initEvent type, true, true
        if data
            event.data = data

        window.dispatchEvent event

    trigger 'load'

    _error = (err)->
        trigger 'error', err


    ##
    floyd.init config, (err, ctx)->
        return _error(err) if err

        stopped = !ctx.stop
        destroyed = !ctx.destroy

        next = (err)->
            return _error(err) if err

            if !stopped && stopped = true

                trigger 'unload'

                ctx.stop next

            else

                if !destroyed && destroyed = true

                    ctx.destroy()

        trigger 'beforeunload'

        next()
