
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
                
                try
                    @_buildButtons @__buttons
                    @_wireMouse()
                    done()
                    
                catch err
                    done(err)
                    
               
                
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
            
            @_process buttons,
                done: (err)=>
                    if err
                        throw err
                        
                each: (action, conf, next)=>    
                                    
                    if typeof conf is 'function'
                        conf =
                            handler: conf
                            
                    @_createPermitedButton action, conf, (err, button)=>
                        return next(err) if err || !button
                                          
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
                        
                        next()
                        
        ##
        ##
        ##
        _createButton: (action, conf, fn)->
            fn null, $('<button/>').addClass action
            
        
        ##
        ##
        ##
        _createPermitedButton: (action, conf, fn)->
            if conf.roles
                @identity.hasRole conf.roles, (err, hasRole)=>  
                    return fn(err) if err || !hasRole
                    
                    @_createButton action, conf, fn
            
            else @_createButton action, conf, fn
                    
            