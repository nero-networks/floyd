#!/usr/bin/env coffee

REPL = require 'floyd/node_modules/coffeescript/repl'

dnode = require 'floyd/node_modules/dnode'
net = require 'net'

sock = net.connect '.floyd/tmp/repl.sock'

local = dnode (proxy, conn)->

    conn.on 'remote', (remote)->
        remote.id (id)=>
            repl = REPL.start
                prompt: id+' $ '
                ignoreUndefined: true
                eval: (input, context, filename, fn)->
                    if input.trim()  is 'exit'
                        process.exit()
                    else
                        remote.eval input, (err, res)->
                            return fn(err.message) if err

                            fn null, res || undefined

            repl.completer = (what, fn)->
                remote.completer what, fn

    stdout: (msg)->
        process.stdout.write msg


sock.pipe(local).pipe sock
