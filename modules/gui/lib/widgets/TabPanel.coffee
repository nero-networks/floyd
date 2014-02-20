module.exports =

    class TabPanel extends floyd.gui.ViewContext

        ##
        ##
        ##
        configure: (config)->
            config = super new floyd.Config

                tabs:
                    _order: []
                    _active: null

                template: ->
                    section class:'Content Tabs', ->

                        ul class:'bar', ->
                            for tab in @_tabs._order
                                attr = {}
                                if tab is @_tabs._active
                                    attr = class:'active'

                                li attr, ->
                                    a href:'#'+tab, (@_tabs[tab])


            , config

            @_tabs = config.tabs
            @_panels = config.panels

            return config

        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err
                
                tabs = @__root.parent().find('ul.bar a')

                tabs.click (e)=>
                    tabs.parent().removeAttr 'class'
                    link = $(e.currentTarget)
                    link.parent().addClass 'active'

                    @_showPanel link.attr('href').replace '#', ''

                    return false;

                @_showPanel @_tabs._active

                done()

        ##
        ##
        ##
        _showPanel: (id)->
            @find('.panel.active').removeClass('active')

            _emit = ()=>
                @_emit 'change',
                    active: id

            if (panel = @find '.'+id).length

                panel.addClass('active')
                _emit()

            else
                config = @_panels[id] || {}

                if typeof config is 'string' || typeof config is 'function'
                    config =
                        content: config

                config = new floyd.Config
                    type: 'gui.ViewContext'
                    data:
                        class: 'panel'
                        active: id

                , @_panels._config ,config
                
                config.id ?= id
                
                config.data.class += ' active '+id

                @_createChild config, (err)=>
                    return @error(err) if err

                    _emit()
