
cp = require 'child_process'

##
##
module.exports =

    ##
    ##
    ##
    exec: (cmd, args, fn)->
        if typeof args is 'function'
            fn = args
            args = []
        args ?= []
        _exec floyd.tools.files.normpath(cmd), args, fn


    ##
    ##
    ##
    execSync: (cmd, args)->
        args ?= []
        _execSync floyd.tools.files.normpath(cmd), args


    ##
    ##
    ##
    sudo: (cmd, args, fn)->
        if typeof args is 'function'
            fn = args
            args = []

        args ?= []
        args.unshift floyd.tools.files.normpath cmd

        _exec '/usr/bin/sudo', args, fn


    ##
    ##
    ##
    sudoSync: (cmd, args)->
        args ?= []

        args.unshift floyd.tools.files.normpath cmd

        _execSync '/usr/bin/sudo', args


    ##
    ##
    ##
    feed: (cmd, args, fn)->
        if typeof args is 'function'
            fn = args
            args = undefined

        _feed floyd.tools.files.normpath(cmd), args, fn


    ##
    ##
    ##
    sudoFeed: (cmd, args, fn)->
        if typeof args is 'function'
            fn = args
            args = undefined

        args.unshift floyd.tools.files.normpath cmd

        _feed '/usr/bin/sudo', args, fn

##
_feed = (cmd, args, fn)->

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

##
_exec = (cmd, args, fn)->

    proc = cp.spawn cmd, args

    if fn
        res = ""
        proc.stdout.on 'data', (data)=>
            res += data

        proc.stdout.on 'end', ()=>
            fn null, res

        proc.stderr.on 'data', (err)=>
            fn new Error err

    return proc

##
_execSync = (cmd, args)->
    cp.spawnSync cmd, args
