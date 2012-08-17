module.exports =
    
    class GuiPopup extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
            
            super new floyd.Config 
                
                data:
                    'parent-selector': 'body'
                            
                children: [ 
                
                    new floyd.Config
                    
                        type: 'gui.ViewContext'
                        
                        data:
                            selector: '.body'
                     
                    , config?.view
                    
                    new floyd.Config
                    
                        type: 'gui.ViewContext'
                        
                        data:
                            selector: '.buttons'
                            
                            content: ->
                                button class:'cancel', 'Abbrechen'
                                button class:'ok', 'Ok'
                        
                        running: ->
                            console.log @find('button')
                            @find('button').click (e)=>
                                console.log $(e.currentTarget).attr('class').split(' ').shift()
                                @parent._emit $(e.currentTarget).attr('class').split(' ').shift(), e
                        
                    , config?.buttons
                    
                    
                    
                ]
                
                template: ->                
                    
                    div id:@id, class: 'gui Popup', ->              
                        div class: 'body floyd-loading'                 
                        div class: 'buttons floyd-loading'
                
                    
            , config
            
         
         
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
            
                
                
        