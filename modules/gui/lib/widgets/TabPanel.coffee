module.exports =

    class TabPanel extends floyd.gui.widgets.List

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

                        ul class:'bar'
                        
                widget: ->
                    attr = {}
                    if @_class
                        attr = class: @_class

                    li attr, ->
                        a href:'#'+@id, @text
                    
                
            , config

            @_tabs = config.tabs
            @_panels = config.panels

            return config
        
        
        ##
        ##
        ##
        _loadData: (offset, limit, fn)->
            if !(_order = @_tabs._order).length
                for key, val of @_tabs
                    if key.charAt(0) isnt '_'
                        _order.push key
            
            @identity.data (err, user)=>
                _hasRole = (roles)=>
                    for role in roles
                        if user?.roles?.indexOf?(role) != -1
                            return true 
                
                tabs = []
                for tab in _order
                    data = @_tabs[tab]
                    if !data.roles || _hasRole data.roles
                        tabs.push _tab =
                            id: tab
                            text: data.text || data
                            _class: data.class || ''
                
                        if tab is @_tabs._active
                            _tab._class = ('active '+_tab._class).trim()
                
                fn null, tabs,
                    offset: offset
                    limit: limit
                    size: tabs.length
        
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
