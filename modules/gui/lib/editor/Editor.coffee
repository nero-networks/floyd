
module.exports = 
    
    class Editor extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
        
            super new floyd.Config

                template: ->
                    div class:'editor Buttons', style:'opacity: .35'
                
                events:
                    'after:booted': ()->
                        @_buildButtons config.buttons
                        @_wireMouse()
                        
            , config
        
        ##
        ##
        ##
        _wireMouse: ()->
            @parent.__root.mouseenter (event)=>
                @__root.css 'opacity', 1

            .mouseleave (event)=>
                @__root.css 'opacity', .35
                
        
        ##
        ##
        ##
        _buildButtons: (buttons)->
            
            _popup = (editor)=>
                floyd.tools.gui.popup @,
                    type: editor.popup || 'gui.widgets.Popup'
                    
                    data:
                        class: editor.class || 'dialog'
                    
                    view: 
                        children: [ editor ]
            
            for action, handler of buttons
                do(action, handler)=>
                    if typeof handler is 'string'
                        handler = 
                            type: handler
                    
                    if typeof handler is 'object'
                        editor = handler
                        
                        handler = (event, open)=>
                            open editor
                            
                    @_createButton action, (err, button)=>
                        @_append button.click (event)=>
                
                            handler.apply @, [event, _popup]
                
                            return false
        
        ##
        ##
        ##
        _createButton: (action, fn)->
            fn null, $('<a href="#'+action+'"><img src="/img/buttons/'+action+'.png"/></a>')
                  
        
            