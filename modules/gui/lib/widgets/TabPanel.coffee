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
                    div class:'Tabs', ->

                        ul class:'bar'

                        div class:'panels'

                widget: ->
                    attr =
                        class: @id
                    if @_class
                        attr.class += ' '+@_class
                    if  @title
                        attr.title = @title

                    li attr, ->
                        a href:'#'+@id, @text

                events:
                    display: ->
                        @_wireTabs()

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

            @_tabs._active ?= _order[0]

            @identity.data (err, user)=>
                _hasRole = (roles)=>
                    for role in roles
                        if user?.roles?.indexOf?(role) != -1
                            return true

                tabs = []
                for tab in _order
                    if !(data = @_tabs[tab])
                        data = floyd.tools.strings.capitalize tab

                    if !data.roles || _hasRole data.roles
                        tabs.push _tab =
                            id: tab
                            text: data.text || data
                            title: data.title
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
        _wireTabs: ()->
            tabs = @_ul.find('>li >a')

            tabs.click (e)=>
                link = $(e.currentTarget)

                @showPanel link.attr('href').substr 1

                return false;

            @showPanel @_tabs._active


        ##
        ##
        ##
        _showPanel: (id)->
            @logger.warning '_showPanel is deprecated! use showPanel instead...'
            @showPanel id

        ##
        ##
        ##
        showPanel: (id)->

            ## suspend and recurse if active tab present and it is not id
            if (active = @_tabs._active) && active isnt id && @children[active]
                @_tabs._active = null

                @logger.debug 'suspending', active
                return @children[active].suspend (err)=>
                    return @logger.error(err) if err

                    @showPanel(id)

            #else
            #    console.log 'not suspending', @_tabs._active, id, !!@children[@_tabs._active]


            if !@_tabs._active
                @_tabs._active = id

                ## resume and recurse if active tab present
                if @children[id]
                    @logger.debug 'resuming', id
                    return @children[id].resume (err)=>
                        return @logger.error(err) if err

                        @showPanel(id)

            #else
            #    console.log 'not resuming', @_tabs._active, id, !!@children[id]

            @find('.panel.active').removeClass 'active'
            @_ul.find('> .active').removeClass 'active'
            @_ul.find('> .'+id).addClass 'active'

            ##
            _emit = ()=>

                @_emit 'change',
                    active: id
                for child in @children
                    child._emit? 'tabs:change',
                        active: id

            if (panel = @find '.panel.'+id).length
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
                        'parent-selector':'.panels'
                        class: 'panel'
                        active: id

                , @_panels._config ,config

                config.id = id

                config.data.class += ' active '+id

                @_createChild config, (err)=>
                    return @error(err) if err

                    _emit()
