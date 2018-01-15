through = require 'through'
DNODE = 'DNODE:'

module.exports =

    class DirectorBridge extends floyd.dnode.Bridge

        _wireMessageQueue: (queue, msg, fn)->

            stream = through (msg)=>
                queue.send DNODE+msg

            queue.on 'message', (msg)=>
                if floyd.tools.strings.begins msg, DNODE
                    stream.queue msg.substr DNODE.length

            @_pipeLocal {}, stream, fn

            if msg
                stream.queue msg.substr DNODE.length
