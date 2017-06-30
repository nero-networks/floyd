
module.exports =

    class RemotePlatform extends floyd.AbstractPlatform

        ##
        ##
        ##
        constructor: (base)->
            settings = base.system || {}

            ## platform type
            settings.platform = 'remote'

            ## platform ident string
            settings.ident = navigator?.userAgent || 'RemotePlatform'

            ## origin hostname
            settings.hostname = location?.hostname.split('.').shift()

            ## os type
            if (_probe = (navigator?.oscpu || 'unknown')).match /[L]inux/
                settings.os = 'linux'

            else if _probe.match /[Ww]in/
                settings.os = 'win'

            else
                settings.os = _probe

            super settings

            for key, value of base
                if key isnt 'system'
                    @[key] = value

            window.process ?=
                nextTick: (fn)->
                    setTimeout fn, 1


            ## setImmediate emulation
            if !window.setImmediate
                pending = []

                triggerID = null
                if window.postMessage
                    window.addEventListener 'message', (e)->
                        if e.origin is location.origin && triggerID && e.data is triggerID
                            if pending.length
                                pending.shift()()

                window.setImmediate = (fn)->
                    if !window.postMessage
                        triggerID = 'floyd-exec-pending-immediate-trigger-'+floyd.tools.strings.uuid()
                        pending.push fn
                        window.postMessage triggerID, location.origin

                    else ## fallback
                        setTimeout fn, 1


        ##
        ##
        ##
        boot: (modules, attempt=0)->

            delayed = {}

            err = null
            for path, init of modules
                do(path, init)=>

                    _list = path.split('.')
                    _list.shift()

                    _root = @
                    name = _list.pop()

                    ## find/create the package container
                    if _list.length > 0
                        for part in _list
                            _root = _root[part] ?= {}


                    try
                        ## 1. collect subpackages that may already be loaded
                        pre = _root[name] || {}

                        ## 2. initialize the package
                        mod = _root[name] = init()

                        ## 3. relocate eventualy loaded subpackages into the package
                        for k, v of pre
                            if !mod[k]
                                mod[k] = v

                        #console.log 'build class', path, _list, part, _root

                    catch e
                        err = e
                        delayed[path] = init

            if ++attempt < 10 && floyd.tools.objects.keys(delayed).length
                #console.log 'delayed build', err, delayed

                @boot delayed, attempt

            else if err
                throw err

            return @
