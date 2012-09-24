
module.exports = 
    
    #
    class ListEditor extends floyd.gui.ViewContext 
        
        configure: (config)->
            
            super new floyd.Config 
            
                children: [

                    new floyd.Config
                        type: 'gui.editor.Editor'
                        
                        template: ->
                            div class:'editor Buttons', style:'display: none', ->
                                div class:'items'

                        _wireMouse: ()->
                            @parent.parent.once 'display', ()=> 
                                @_wireMouse()
                            
                            @parent.parent.__root.find('> ul > li') 
                            
                            .mouseenter (event)=>
                                @parent._allow event, ()=>
                                    $(event.currentTarget).append @__root
                                    @__root.show()
                                
                            .mouseleave (event)=>
                                @__root.hide()
                                @parent.__root.append @__root
                                
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
                 