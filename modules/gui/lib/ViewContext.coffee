

module.exports =

    class ViewContext extends floyd.Context

        ##
        ##
        ##
        configure: (config)->
            @_hiddenKeys.push 'wire', 'wiring', 'build', 'building'

            @_template ?= config.template


            floyd.tools.objects.intercept @, 'boot', (done, boot)=>

                @_build (err)=>
                    return done(err) if err

                    boot (err)=>
                        return done(err) if err
                        if floyd.system.platform is 'remote'
                            @wire done

                        else
                            @build done


            config = super new floyd.Config

                data:
                    class: config.class
                    selector: undefined

                    elements:
                        root: '<div class="floyd-loading"/>'

            , config

            if config.widget
                @_widget = floyd.tools.gui.ck config.widget

            if !@_content && typeof (@_content = config.data.content || config.content) is 'function' && !config.data.raw
                @_content = floyd.tools.gui.ck @_content

            return config

        ##
        ##
        ##
        boot: (done)->

            super done

            if @data.content
                @logger.info '@data.content is deprecated. use @content instead -', @type, @ID, @data.content

            if @data.attr
                @__root.attr @data.attr

            if (cls=@data.class) && !@__root.hasClass cls
                @__root.addClass cls


        ##
        ##
        ##
        wire: (done)->
            @_emit 'wiring'
            @wiring?()

            done()

        ##
        ##
        ##
        build: (done)->
            if @building
                @building done

            else
                done()

        ##
        ##
        ##
        find: ()->
            @__root.find.apply @__root, arguments



        ##
        ##
        ##
        _build: (done, stage=0)->

            #@logger.info 'booting stage', stage

            _sel = (selector, parent)=>
                if typeof selector is 'string'
                    $ selector, parent

                else if selector
                    selector.apply @, [parent]

            ##
            ## get the root element to represent the context
            if stage is 0

                ## element is already there, found by selector -> stage 1
                if @data.selector && ( @__root = _sel @data.selector, @parent?.__root )?.length
                    @__root.attr 'id', @id

                    @_build done, 1

                ## or by id -> stage 1
                else if ( @__root = $ '#'+@id )?.length

                    @_build done, 1

                ## render root element, append to parent and recurse @_build
                else
                    @_create (err, ele)=>
                        return done(err) if err

                        if !@data['parent-selector'] && @parent?._append

                            @parent._append ele, (err)=>
                                return done(err) if err

                                @_build done, 0

                        else if (__parentNode = _sel(@data['parent-selector'], @parent.__root))?.length
                            __parentNode.append ele
                            @_build done, 0

                        else
                            _sel(@data['parent-selector'] || 'body').append ele
                            @_build done, 0

            ##
            ## create content
            else if stage is 1

                if @__root.hasClass 'floyd-loading'

                    @_emit 'loading'

                    @_refresh (err)=>
                        return done(err) if err

                        @__root.removeClass 'floyd-loading'
                        if !@__root.attr('class')?.length
                            @__root.removeAttr 'class'

                        @_emit 'loaded'

                        @_build done, 2

                else
                    @_build done, 2

            ## stage 2 -> ready
            else
                @forIdentity @identity, (err, ctx)=>
                    return done(err) if err

                    @__root.data 'floyd', ctx

                    done()


        ##
        ##
        ##
        _create: (fn)->

            next = (err, data)=>

                if data
                    ele = $(data)

                    if !ele.attr('id')
                        ele.attr 'id', @id

                fn err, ele

            if typeof @_template is 'function'

                (floyd.tools.gui.ck @_template)
                    format: @data.find('debug')
                    context: @

                , next

            else
                next null, (@_template ? @data.elements.root)


        ##
        ##
        ##
        _append: (ele, fn)->

            @__root.append(ele) if ele

            fn?()


        ##
        ##
        ##
        _refresh: (fn)->

            @_load (err, data)=>

                return fn(err) if err or !data

                @_update data, fn


        ##
        ##
        ##
        _load: (fn)->

            if typeof @_content is 'function'

                if @data.raw
                    @_content.apply @, [fn]

                else
                    @_content
                        format: @data.find('debug')
                        context: @
                    , fn


            else if !@data.raw
                floyd.tools.gui.md @_content, fn

            else
                fn null, @_content
        ##
        ##
        ##
        _update: (data, fn)->

            @_append data, fn


        ##
        ##
        ##
        _display: (data, options, fn)->

            item = if @data.key then data[@data.key] else data

            @_item item, (err, html)=>
                return fn?(err) if err

                if html
                    @__root.append html

                fn?()


        ##
        ##
        ##
        _item: (item, fn)->

            @_prepare item, (err, context)=>
                return fn(err) if err

                if @_widget
                    @_widget
                        format: @data.find 'debug'
                        context: context
                    , fn

                else
                    fn null, context
        ##
        ##
        ##
        _prepare: (item, fn)->

            item = floyd.tools.objects.clone item

            item.__data = @data

            fn null, item


        ##
        ##
        ##
        _getBackend: (fn)->
            return fn(null, @__BACKEND) if @__BACKEND

            @lookup @data.find('backend', 'backend'), @identity, (err, ctx)=>
                return fn(err) if err

                fn null, @__BACKEND = ctx

        ##
        ##
        ##
        _getOrigin: (fn)->
            return fn(null, @__ORIGIN) if @__ORIGIN

            @lookup @data.find('origin'), @identity, (err, ctx)=>
                return fn(err) if err

                fn null, @__ORIGIN = ctx

        ##
        ##
        ##
        _href: (href)->

            encodeURI @data.find('hrefBase', '/')+href

        ##
        ##
        ##
        #_populate: (data, opt, fn)->
        #    for name, value of data
        #        do (name, value)=>
        #            ele = @find opt?[name]?.selector || '.'+name
        #            ele[opt?[name]?.method || 'text'] opt?[name]?.format?(ele) || opt?[name]?(ele) || value
        #    fn?()
