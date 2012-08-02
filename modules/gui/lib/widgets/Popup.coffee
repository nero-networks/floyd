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
                            @find('button').click (e)=>
                                @parent._emit $(e.currentTarget).attr('class').split(' ').shift(), e
                        
                    , config?.buttons
                    
                    
                    
                ]
                
                template: ->                
                    
                    div id:@id, class: 'gui Popup', ->              
                        div class: 'body floyd-loading'                 
                        div class: 'buttons floyd-loading'
                
                running: ->
                
                    if @data['parent-selector'] is 'body'
                        $('body').css overflow: 'hidden'
                        
                shutdown: ->
                    if @data['parent-selector'] is 'body'
                        $('body').css overflow: 'auto'
                    
                    
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
            
                
                
        