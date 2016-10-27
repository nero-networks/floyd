
net = require 'net'
REPL = require 'coffee-script/repl'
through = require 'through'

dnode = require 'dnode'

module.exports =

    ##
    ##
    ##
    class ReplContext extends floyd.Context

        ##
        configure: (config)->
            super new floyd.Config
                data:
                    port: '.floyd/tmp/repl.sock'
            , config

        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err

                @_createServer (sock)=>
                    @_createLocal (err, local)=>
                        sock.pipe(local).pipe sock

                .listen @data.port

                @logger.info 'repl listening on port', @data.port

                done()

        ##
        ##
        ##
        _createLocal: (done)->

            done null, dnode (proxy, conn)=>

                remote = null
                conn.on 'remote', (rem)=>
                    remote = rem

                input = through (data)=>
                    input.queue data
                , ()=>
                    input.queue null

                output = through (data)=>
                    output.queue data
                , ()=>
                    output.queue null

                output.on 'data', (data)=>
                    remote?.stdout data

                output.on 'error', (err)=>
                    remote?.stderr err.stack || err.message || err

                repl = REPL.start
                    input: input
                    output: output

                @_exposedContext (err, ctx)=>
                    repl.context.err = err if err
                    repl.context.ctx = ctx if ctx


                ## remote api
                eval: (input, fn)=>
                    @logger.debug 'repl eval', input
                    repl.eval input, repl.context, 'repl-client', fn

                completer: (what, fn)=>
                    @logger.debug 'repl complete', what
                    repl.completer what, fn


        ##
        ##
        ##
        _createServer: (handler)->
            net.createServer handler

        ##
        ##
        ##
        _exposedContext: (fn)->
            fn null, @
