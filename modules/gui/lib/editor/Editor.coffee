
module.exports = 
    
    class Editor extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
        
            super new floyd.Config

                template: ->
                    div class:'editor Buttons floyd-loading', style:'opacity: .35'
                
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
            
            for action, conf of buttons
                do(action, conf)=>
                                    
                    if typeof conf is 'function'
                        conf =
                            handler: conf
                            
                    @_createButton action, conf, (err, button)=>
                        if conf.text
                            button.text conf.text
                        
                        if conf.title
                            button.attr 'title', conf.title
                            
                        @_append button.click (event)=>
                            if conf.handler
                                conf.handler.apply @, [event, _popup]
                            
                            else
                                @_emit action,
                                    event: event
                                    open: _popup
                                
                            return false
        
        ##
        ##
        ##
        _createButton: (action, conf, fn)->
            fn null, $('<button/>').addClass action
                  
        
            