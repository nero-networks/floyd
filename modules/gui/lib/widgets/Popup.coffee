module.exports =
    
    class GuiPopup extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
            
            children = [
            
                new floyd.Config
                        
                    type: 'gui.ViewContext'
                    
                    data:
                        selector: '.body'
                 
                , config?.view
                
            ]
            
            if config?.buttons
            
                children.push new floyd.Config
                        
                    type: 'gui.ViewContext'
                    
                    data:
                        selector: '.buttons'
                        
                        content: ->
                            button class:'cancel', 'Abbrechen'
                            button class:'ok', 'Ok'
                    
                    booted: ->
                        @view = @parent.children[0]
                        
                        @find('button').click (e)=>
                            action = $(e.currentTarget).attr('class').split(' ').shift()
                            
                            @_emit action, e
                            @parent._emit action, e
                            
                    
                , config?.buttons
            
            super new floyd.Config 
                
                data:
                    'parent-selector': 'body'
                            
                children: children
                
                template: ->                
                    
                    div id:@id, class: 'gui Popup', style:'display: none', ->              
                        div class: 'body floyd-loading'                 
                        div class: 'buttons floyd-loading'
                
                
                    
            , config
            
         
        start: (done)->
            super (err)=>
                done(err) if err
                
                @__root.fadeIn 'slow', done
         
        ##
        ##
        ## 
        append: (ele)->
            @find('.body').append ele
        
        
        ##
        ##
        ##
        close: (fn)->
            @_emit 'close'
            fn?()
            
        ##
        ##
        ##
        fadeOut: (speed='slow', fn)->
            @__root.fadeOut speed, ()=>
                @close fn
                
        