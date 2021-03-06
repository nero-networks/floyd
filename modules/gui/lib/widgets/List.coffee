
qs = require('querystring')

module.exports =

    class List extends floyd.gui.ViewContext

        ##
        ##
        ##
        configure: (config)->
            config = super new floyd.Config

                widget: ->
                    if @class
                        li class:@class, @text
                    else
                        li @text

                data:
                    items: []
                    limit: -1
                    offset: 0
                    listSelector: ->
                        $ @find('ul')[0]

                content: ->
                    if @data.headline
                        h2 @data.headline
                    ul()

            , config

            if config.browse

                config.children.push new floyd.Config

                    type: 'gui.widgets.ListBrowser'

                    data:
                        search: config.data?.search
                        selector: '> div.browse'

                    events:
                        browse: (e)->
                            @parent._loadData e.offset, e.limit, (err, items, data)=>
                                return done(err) if err
                                @parent._display items, data

                    booted: ->
                        @parent.on 'display', (e)=>
                            @_display e.items, e.data


                , config.browse

            @_widget = floyd.tools.gui.ck config.widget

            return config


        ##
        boot: (done)->
            super (err)=>
                return done(err) if err

                if typeof (_sel = @data.listSelector) is 'function'
                    @_ul = _sel.apply @, []
                else
                    @_ul = @find _sel

                done()

        ##
        start: (done)->
            super (err)=>
                return done(err) if err

                if !@_ul.children().length
                    @_reload done

                else done()


        ##
        _reload: (done)->
            if @data.search
                query = if location.search then qs.parse location.search.substr 1 else {}
                @data.offset = parseInt(query[@data.search] ?= '0') * @data.limit

            _done = (err)=>
                if !done
                    @logger.error(err) if err

                else done err

            @_loadData @data.offset, @data.limit, (err, items, data)=>
                return _done(err) if err
                @_display items, data, done



        _loadData: (offset, limit, fn)->

            if @data.loadData

                @_getBackend (err, ctx)=>
                    return fn(err) if err

                    ctx[@data.loadData] offset, limit, fn

            else

                items = []

                if (_items = @data.items)
                    if limit > -1
                        _items = _items.slice offset, offset+limit
                    else
                        _items = _items.slice offset

                    for item in _items
                        if typeof item is 'string'
                            items.push item
                        else
                            items.push floyd.tools.objects.clone item

                fn null, items,
                    offset: offset
                    limit: limit
                    size: @data.items?.length || 0


        ##
        ##
        ##
        _display: (items, data, fn)->
            if @data.key
                items = floyd.tools.objects.resolve @data.key, items, false


            @_emit 'before:display'

            @_ul.html ''
            @_items = items
            @_elements = []

            @_process items,

                each: (item, next)=>
                    @_item item, (err, html)=>

                        if html
                            html = $ html
                            @_elements.push html
                            @_ul.append html

                        next err

                done: (err)=>
                    return fn(err) if err

                    @_emit 'display',
                        items: items
                        data: data

                    fn?()
        ##
        ##
        ##
        _prepare: (item, fn)->
            if !floyd.tools.objects.isObject item
                item =
                    text: item

            if @format
                item.text = @format item.text

            super item, fn
