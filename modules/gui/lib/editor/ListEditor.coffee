
module.exports =

    #
    class ListEditor extends floyd.gui.ViewContext

        configure: (config)->

            super new floyd.Config
                data:
                    class: 'ListEditor'
                    itemSelector: '> ul > li'

                children: [

                    new floyd.Config
                        type: 'gui.editor.Editor'

                        data:
                            class: 'each'
                            events:
                                delegate: true

                        template: ->
                            div class:'editor Buttons floyd-loading', style:'display: none'

                        _wireMouse: ()->
                            @parent.parent.once 'before:display', ()=>
                                @parent.__root.append @__root

                            @parent.parent.once 'display', ()=>
                                @_wireMouse()

                            items = @parent.parent.find(@data.find 'itemSelector')

                            if @parent.data.displayType is 'clone'

                                clone = @__root.clone()
                                clone.removeAttr 'id'
                                clone.show()

                                ref = items.find '.editor.Buttons'
                                if ref.length
                                    for ele in ref
                                        $(ele).replaceWith clone.clone()
                                else
                                    items.append clone

                                items = @parent.parent.find(@data.find 'itemSelector')

                                for action, conf of @_buttons
                                    do (action, conf)=>
                                        items.find('.editor.Buttons > .'+action).click conf.handler


                            else # default: mouseover

                                items.mouseenter (event)=>
                                    @parent._allow event, ()=>
                                        $(event.currentTarget).append @__root
                                        @_show(event)


                                items.mouseleave (event)=>
                                    @parent.__root.append @__root
                                    @_hide(event)

                        ##
                        _show: ()->
                            @__root.show()

                        ##
                        _hide: ()->
                            @__root.hide()

                    , config.each

                ]

            , ->

                if config.add
                    console.warn 'DEPRECATED: config.add is deprecated, use config.buttons.add instead'
                    config.buttons ?= {}
                    config.buttons.add = config.add

                if config.buttons
                    @children.push

                        type: 'gui.editor.Editor'

                        data:
                            class: 'add'
                            events:
                                delegate: true

                        buttons: config.buttons

            , config


        ##
        ##
        _allow: (event, ok)->
            ok()
