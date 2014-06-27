
module.exports = 
    
    class Editor extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
        
            config = super new floyd.Config
                
                data:
                    popup:
                        fade: false
                
                template: ->
                    div class:'editor Buttons floyd-loading', style:'opacity: .35'
                
            , config
            
            @__buttons = config.buttons
            
            return config
        
        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err
                
                @_buildButtons @__buttons
                @_wireMouse()
                
                done()
               
                
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
            
            _popup = (editor, fn)=>
                editor.type ?= 'gui.ViewContext'
                
                floyd.tools.gui.popup @,
                    type: editor.popup || 'gui.widgets.Popup'
                    
                    data:
                        class: editor.class || 'dialog'
                        fade: @data.popup.fade
                    
                    view: 
                        children: [ editor ]
                , fn
                
            for action, conf of buttons
                do(action, conf)=>
                                    
                    if typeof conf is 'function'
                        conf =
                            handler: conf
                            
                    @_createButton action, conf, (err, button)=>
                                                
                        if typeof conf is 'string'
                            conf =
                                text: conf

                        if typeof conf is 'function'
                            conf =
                                handler: conf
                        
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
                                    root: @__root
                                    parent: @__root.parent()
                                
                            return false
        
        ##
        ##
        ##
        _createButton: (action, conf, fn)->
            fn null, $('<button/>').addClass action
                  
        
            