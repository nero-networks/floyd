
module.exports =

    class PageContext extends floyd.gui.HttpContext

        configure: (config)->

            super new floyd.Config

                data:
                    file: '/index.html'

                    contentContextId: 'content'

                permissions:
                    readFile:
                        roles: ['editor', 'admin']

                    writeFile:
                        roles: ['editor', 'admin']

                remote:

                    children: []

                    booted: ->

                        ## gets called twice: 1. local->obfuscate, 2. remote->rebuild
                        floyd.tools.gui.email.obfuscate $ 'body'

            , config

        ##
        ##
        ##
        isPageContext: ()->
            return true


        ##
        ##
        ##
        start: (done)->

            file = @_contentFile()

            if !floyd.tools.files.exists file
                floyd.tools.files.write file, '# '+@id+'\n'
                floyd.tools.files.chmod file, '664'

            @_reloadContent file

            prev = floyd.tools.files.stat file

            @_watcher = floyd.tools.files.watch file, (event)=>

                if event is 'change'
                    curr = floyd.tools.files.stat file

                    if curr.mtime isnt prev.mtime
                        prev = curr

                        @_reloadContent file

            ##
            super done


        ##
        ##
        ##
        stop: (done)->
            try
                @_watcher?.close()
            catch e
                return done e

            super done

        ##
        ##
        ##
        _createModel: (req, res, type, fn)->
            if typeof type is 'function'
                fn = type
                type = 'remote'

            super req, res, type, (err, model)=>
                return fn(err) if err

                if req.session.user
                    model.type ?= 'dnode.Bridge'

                fn null, model




        ##
        ##
        ##
        _contentFile: ()->

            path = []

            if filepath = @data.find 'filepath'
                path.push(filepath)

            _parent = @parent

            while _parent.isPageContext
                path.unshift _parent.id

                _parent = _parent.parent

            path.push @id

            return './content/'+path.join('/')+'.md'


        ##
        ##
        ##
        _reloadContent: (file)->
            #console.log @ID, 'reading file', file, floyd.tools.files.exists file

            data = floyd.tools.files.read file

            ##
            @__file =
                data: data || ''
                name: file

            ##
            _findChild = (id, cfg)->
                #console.log 'search', id, cfg.id, cfg.id is id

                if cfg.id is id
                    #console.log 'found', id
                    return cfg

                if _i = id.indexOf '\.'
                    _id = id.substr 0, _i
                    _rest = id.substr _i+1

                    #console.log 'id:', id, '_id:', _id, '_rest:', _rest

                    for child in cfg.children || []
                        if child.id is (_id || id)

                            #console.log _rest, ' --> ', child.id
                            return _findChild(_rest, child)

            ##

            if child = _findChild @data.contentContextId, @_model.local
                child.content = @__file.data
                #console.log child

            else

                throw new Error 'no contentContext defined for id '+@data.contentContextId


        ##
        ##
        ##
        readFile: (fn)->

            fn null, @__file.data


        ##
        ##
        ##
        writeFile: (data, fn)->

            floyd.tools.files.write @__file.name, data

            fn?()
