
module.exports =

    class Editor extends floyd.gui.ViewContext

        ##
        ##
        ##
        configure: (config)->

            config = super new floyd.Config

                data:
                    popup:
                        fade: false

                template: ->
                    div class:'editor Buttons floyd-loading'

            , config

            @__buttons = config.buttons

            return config

        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err

                try
                    @_buildButtons @__buttons
                    @_wireMouse()
                    done()

                catch err
                    done(err)



        ##
        ##
        ##
        _wireMouse: ()->

        ##
        ##
        ##
        _buildButtons: (buttons)->

            _popup = (editor, fn)=>
                editor.type ?= 'gui.ViewContext'

                confirmClose = editor.confirmClose
                clazz = editor.class || 'dialog'
                fade = editor.fade || @data.popup.fade

                floyd.tools.gui.popup @,
                    type: editor.popup || 'gui.widgets.Popup'

                    data:
                        class: clazz
                        fade: fade

                    ## TODO: check and if possible remove children and change to view: editor
                    view:
                        children: [ editor ]

                    confirmClose: (fn)->
                        if confirmClose
                            if typeof confirmClose is 'function'
                                @children[0].children[0].confirmClose fn

                            else if typeof confirmClose is 'string'
                                if confirm confirmClose
                                    fn()

                            else fn()

                        else fn()

                , fn

            @_buttons = {}
            @_process buttons,
                done: (err)=>
                    if err
                        throw err

                    _actions = floyd.tools.objects.keys @_buttons
                    _order = buttons._order || _actions
                    for action in _order
                        @_append @_buttons[action].element
                    for action in _actions
                        if action isnt '_order' && _order.indexOf(action) is -1
                            @_append @_buttons[action].element

                each: (action, conf, next)=>
                    return next() if action is '_order'

                    if typeof conf is 'function'
                        conf =
                            handler: conf

                    @_createPermitedButton action, conf, (err, button)=>
                        return next(err) if err || !button

                        if typeof conf is 'string'
                            conf =
                                text: conf

                        if typeof conf is 'function'
                            conf =
                                handler: conf

                        if conf.text
                            button.text conf.text
                        else
                            button.addClass conf.class || 'icon'

                        if conf.title
                            button.attr 'title', conf.title

                        @_buttons[action] = {}
                        @_buttons[action].element = button.click @_buttons[action].handler = (event)=>

                            if conf.handler
                                conf.handler.apply @, [event, _popup]

                            else
                                @_emit action,
                                    event: event
                                    open: _popup
                                    root: @__root
                                    parent: @__root.parent()

                            return false

                        next()

        ##
        ##
        ##
        _createButton: (action, conf, fn)->
            fn null, $('<button/>').addClass action


        ##
        ##
        ##
        _createPermitedButton: (action, conf, fn)->
            if conf.roles
                @identity.hasRole conf.roles, (err, hasRole)=>
                    return fn(err) if err || !hasRole

                    @_createButton action, conf, fn

            else @_createButton action, conf, fn
