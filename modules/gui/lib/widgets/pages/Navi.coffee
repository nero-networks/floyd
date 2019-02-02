
module.exports =

    class NaviContext extends floyd.gui.ViewContext

        configure: (config)->

            super new floyd.Config

                template: ->
                    nav class:'gui widgets pages Navi floyd-loading'

                ##
                content: ->
                    path = location.pathname

                    bullets = @data.bullets

                    isEditor = @identity.hasRole(['editor'])

                    list = (items, depth=0)->
                        _i=0

                        ul class:('depth'+depth), ->

                            for href, item of items
                                if isEditor || !item.hidden
                                    li ->
                                        attribs =
                                            href: href
                                        _href = if href is '/' then '/home/' else href
                                        if path.substr(0, _href.length) is _href
                                            active = true
                                            attribs.class = 'active'

                                        else
                                            active = false

                                        a attribs, ->

                                            if bullets && depth <= (bullets.depth||0)
                                                span class: 'bullet', ->
                                                    if bullets.type is 'numbers'
                                                        text if _i < 10 then '0'+(_i++) else _i++
                                                        text ' | '
                                                    else if bullets.type is 'letters'
                                                        text String.fromCharCode 97 + _i++
                                                        text ' | '

                                            span class: 'text', (item.text || item)

                                        if isEditor || active && item.items && floyd.tools.objects.values(item.items).length
                                            list item.items, depth + 1

                    ##
                    if typeof (_items=@data.items) is 'function'
                        _items.apply @, [(err, items)=> list items]

                    else
                        list _items


            , config

        ##
        _refresh: (done)->
            if !@data.items
                floyd.tools.objects.intercept @, '_load', (done, _load)=>
                    @_getNavi (err, items)=>
                        @data.items = items
                        _load done

            super done

        ##
        _getNavi: (fn)->
            @lookup @data.find('origin'), @identity, (err, ctx)=>
                return fn(err) if err
                ctx.getNavi fn
