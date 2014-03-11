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
                    
                    attribs = 
                        type:@data.type
                        name:@data.name
                    
                    attribs.disabled = 'disabled' if @data.disabled
                    attribs.readonly = 'readonly' if @data.readonly
                    
                    input attribs

                    button class:'icon '+@data.dropdown.button, title: @data.text, name: @data.dropdown.button, ->
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
                    
                    format: config.format
                    parse: config.parse
                    
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
        wire: (done)->
            super (err)=>
                return done(err) if err

                dropdown = @find '.dropdown'
                
                @_wireItems()
                
                @_dropdown.on 'display', ()=>
                    @_wireItems()
                
                @_input = @find('[name='+@data.name+']').change (e)=>
                    if (val = @_input.val()) isnt @_value
                        @_setAction '_custom_', val
                
                @find('[name='+@data.dropdown.button+']').click (e)=>
                    $('.dropdown').not(dropdown).fadeOut().parent().removeClass 'activeBox';
                    
                    if @__root.hasClass 'activeBox'
                        @__root.removeClass 'activeBox'
                        dropdown.hide()
                        
                    else
                        @__root.addClass 'activeBox'
                        
                        if @_dropdown._updateData
                            @_dropdown._updateData (err)=>
                                return alert(err.message) if err
                                dropdown.show()
                                
                        else dropdown.show()
                        
                    return false

                $(document).click ()=>
                    dropdown.fadeOut()
                    @__root.removeClass 'activeBox';

                ##
                done()

        
        ##
        ##
        ##
        _wireItems: ()->
            dropdown = @find '.dropdown'

            dropdown.find('li').click (e)=>
                li = $(e.currentTarget)

                if cls=li.attr('class')
                    @_setAction cls.split(' ').pop(), li.text()

                else
                    @_setAction li.text(), li.text()
                
                dropdown.hide()
                @__root.removeClass 'activeBox'
                return false
            
        
        ##
        ##
        ##
        _loadData: (fn)->

            fn null, @data.items
        
        ##
        ##
        ##
        _display: (items, action, value, fn)->
            action ?= items?[0]
            value ?= action
            @_setAction action, value
            @_dropdown._display? items, {}, fn
            
        
        
        ##
        ##
        ##
        _setAction: (@_action, @_value)->
            
            @_input.val @_value
            
            if !@data.readonly
                @_input.focus()
            
            @_input.data 'action', @_action
            
            @_emit 'change',
                name: @data.name
                action: @_action
                value: @_value
        