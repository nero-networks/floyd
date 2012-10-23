
module.exports = 
    
    #
    class ListEditor extends floyd.gui.ViewContext 
        
        configure: (config)->
            
            super new floyd.Config 
                data:
                    itemSelector: '> ul > li'
                    
                children: [

                    new floyd.Config
                        type: 'gui.editor.Editor'
                        
                        template: ->
                            div class:'editor Buttons', style:'display: none'

                        _wireMouse: ()->
                            @parent.parent.once 'display', ()=> 
                                @_wireMouse()
                            
                            @parent.parent.find(@data.find 'itemSelector') 
                            
                            .mouseenter (event)=>
                                @parent._allow event, ()=>
                                    $(event.currentTarget).append @__root
                                    @_show()
                                    
                                
                            .mouseleave (event)=>
                                @_hide()
                                
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
                        
                        buttons:
                            add: config.add
                        
                        _wireMouse: ()->
    
                            @parent.parent.__root.mouseenter (event)=>
                                @__root.css 'opacity', 1
                                
                            .mouseleave (event)=>
                                @__root.css 'opacity', .35
            , config
            
        
        ##
        ##
        _allow: (event, ok)->
            ok()
                 