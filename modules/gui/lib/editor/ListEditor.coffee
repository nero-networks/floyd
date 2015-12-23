
module.exports = 
    
    #
    class ListEditor extends floyd.gui.ViewContext 
        
        configure: (config)->
            
            super new floyd.Config 
                data:
                    class: 'ListEditor'
                    itemSelector: '> ul > li'
                    
                children: [

                    new floyd.Config
                        type: 'gui.editor.Editor'
                        
                        data:
                            class: 'each'
                            events:
                                delegate: true
                                
                        template: ->
                            div class:'editor Buttons floyd-loading', style:'display: none'

                        _wireMouse: ()->
                            @parent.parent.once 'before:display', ()=>
                                @parent.__root.append @__root     
                                                
                            @parent.parent.once 'display', ()=>                     
                                @_wireMouse()
                            
                            @parent.parent.find(@data.find 'itemSelector') 
                            
                            .mouseenter (event)=>
                                @parent._allow event, ()=>
                                    $(event.currentTarget).append @__root
                                    @_show(event)
                                    
                                
                            .mouseleave (event)=>
                                @parent.__root.append @__root
                                @_hide(event)
                                
                        ##
                        _show: ()->
                            @__root.show()
                        
                        ##
                        _hide: ()->
                            @__root.hide()
                          
                    , config.each
                
                ]
                
            , ->
                
                if config.add
                    @children.push
                    
                        type: 'gui.editor.Editor'
                        
                        data:
                            class: 'add'
                            events:
                                delegate: true
                                
                        buttons:
                            add: config.add
                        
            , config
            
        
        ##
        ##
        _allow: (event, ok)->
            ok()
                 