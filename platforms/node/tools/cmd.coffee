
cp = require 'child_process'

##
##
module.exports =

    feed: (cmd, args, fn)->
        if typeof args is 'function'
            fn = args
            args = undefined

        proc = cp.spawn cmd, args

        proc.stdout.on 'data', (data)=>
            for chunk in data.toString().split '\n'
                if chunk
                    fn null, chunk

        proc.stdout.on 'end', ()=>
            fn null, '<EOF>'

        proc.stderr.on 'data', (err)=>
            fn new Error err

        return proc
