module.exports =

    class ComboBox extends floyd.gui.ViewContext

        ##
        ##
        ##
        configure: (config)->
            config = super new floyd.Config

                template: ->
                    div class:'ComboBox floyd-loading'


                content: ->

                    input type:@data.type, name:@data.name

                    button class:'icon '+@data.dropdown.button, title: @data.text, ->
                        span @data.text

                    div class:'dropdown '+@data.dropdown.class+' floyd-loading', style:'display:none'


                data:

                    type: 'text'

                    name: 'value'

                    dropdown:
                        button: 'select'
                        class: 'right down'

                    text: 'Auswahl'

                dropdown:

                    type: 'gui.widgets.List'

                    data:
                        selector: 'div.dropdown'

                    _loadData: (offset, limit, fn)->
                        @parent._loadData (err, _items)=>
                            if floyd.tools.objects.isArray _items
                                items = _items

                            else
                                items = []
                                for key, value of _items
                                    items.push
                                        class: key
                                        text: (value.text || value)

                            fn null, items

            , config

            @__dropdown = config.dropdown

            return config

        ##
        ##
        ##
        boot: (done)->
            super (err)=>
                return done(err) if err

                if @__dropdown
                    @_createChild @__dropdown, (err, @_dropdown)=>
                        done err

        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err

                @_input = @find '[name='+@data.name+']'

                dropdown = @find '.dropdown'

                dropdown.find('li').click (e)=>
                    li = $(e.currentTarget)

                    if cls=li.attr('class')
                        @_setAction cls.split(' ').pop(), li.text()

                    else
                        @_setAction li.text(), li.text()

                    dropdown.hide().parent().removeClass 'activeBox'
                    return false

                @find('.'+@data.dropdown.button).click (e)=>
                    $('.dropdown').not(dropdown).fadeOut().parent().removeClass 'activeBox';

                    if @__root.hasClass 'activeBox'
                        dropdown.hide().parent().removeClass 'activeBox'

                    else
                        @__root.addClass 'activeBox'

                        @_dropdown._updateData (err)=>
                            return alert(err.message) if err
                            dropdown.show()

                    return false

                $(document).click ()=>
                    dropdown.fadeOut().parent().removeClass 'activeBox';

                ##
                done()


        ##
        ##
        ##
        _loadData: (fn)->

            fn null, @data.items

        ##
        ##
        ##
        _setAction: (@_action, @_value)->

            @_input.focus().val @_value

            @_emit 'change',
                name: @data.name
                action: @_action
                value: @_value
