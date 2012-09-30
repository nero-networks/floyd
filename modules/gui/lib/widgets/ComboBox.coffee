module.exports =

    class ComnboBox extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config

                template: ->
                    div class:'ComboBox floyd-loading', ->
                
                data:
                    
                    name: 'value'
                    
                    event: 'change'
                    
                    dropdown:
                        button: 'select'
                        class: 'left down'
                    
                    text: 'Auswahl'
                    
                    content: ->
                        
                        input name:@data.name
                        
                        button class:'icon '+@data.dropdown.button, title: @data.text, ->
                            span @data.text
                        
                        div class:'dropdown '+@data.dropdown.class+' floyd-loading'
                    
                    items: []
                    
                    
                children: [
                
                    type: 'gui.widgets.List'
                    
                    data:
                        selector: 'div.dropdown'
                    
                    _loadData: (offset, limit, fn)-> @parent._loadData fn            
                    
                ]
            
            , config

        
        
        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err
                
                @_input = @find('[name='+@data.name+']').on @data.event, (e)=>
                    @_emit @data.name, 
                        action: @_action
                        value: @_text
                        
                        event: e
                
                dropdown = @find('.dropdown')
                
                dropdown.find('li').click (e)=>
                    li = $(e.currentTarget)
                    
                    @_setAction li.attr('class').split(' ').pop(), li.text() 
                    
                    dropdown.hide()
                
                @find('.'+@data.dropdown.button).click (e)=>
                    dropdown.toggle()
                    
                    return false
                
                $(document).click ()=> 
                    dropdown.fadeOut();
                
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
        
            @_input.val @_value
            
            
            
            