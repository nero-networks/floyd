module.exports =
    
    class GuiPopup extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
            
            ##
            ##
            children = [
            
                new floyd.Config
                        
                    type: 'gui.ViewContext'
                    
                    data:
                        selector: '.body'
                        events:
                            delegate: true
                        
                    booted: ->
                        if @parent.children[1]
                            @buttons = @parent.children[1]
                        
                , config?.view
                
            ]
            
            ##
            ##
            if config?.buttons
            
                children.push new floyd.Config
                        
                    type: 'gui.ViewContext'
                    
                    data:
                        selector: '.buttons'
                        events:
                            delegate: true
                        
                    content: ->
                        button class:'cancel', 'Abbrechen'
                        button class:'ok', 'Ok'
                    
                    booted: ->
                        @view = @parent.children[0]
                        
                        #floyd.tools.objects.intercept @ '_emit', (args..., _emit)=>
                        #    _emit.apply @, args
                        #    @parent._emit.apply @parent, args
                        
                        @find('button, a').click (e)=>
                            action = $(e.currentTarget).attr('class').split(' ').shift()

                            @_emit action, e
                            
                    
                , config.buttons
            
            ##
            ##
            super new floyd.Config 
                
                data:
                    'parent-selector': 'body'
                    close: true
                    fade: true
                            
                children: children
                
                template: ->                
                    
                    div id:@id, class:'gui Popup hidden', ->
                        div class: 'modal', -> div()
                        
                        div class: @data.class, ->
                            div class: 'popup-wrapper', ->
                                div class: 'popup-cell', ->
                                    div class: 'popup-box-wrapper', ->
                                        
                                        if @data.close
                                            a href:'#', class:'close', title:'schließen', ->
                                                img src:'/img/buttons/close.png'
                                        
                                        div class: 'popup-box', ->
                                            div class: 'popup-content', ->
                                                
                                                div class: 'body floyd-loading'
                                                if @children.length > 1                
                                                    div class: 'buttons floyd-loading'

                    
            , config
            
         
        ##
        ##
        ## 
        start: (done)->
            super (err)=>
                return done(err) if err
                
                if floyd.system.platform is 'remote'
                    @find('button.close, a.close').click ()=> 
                        @close()
                    
                    setTimeout ()=>
                        
                        if @data.fade
                            @__root.fadeIn 'slow'
                        
                        else
                            @__root.show()
                    
                    , 100 ## das merkt man sogut wie nicht und die gui wirkt stabiler dadurch... weniger aufbau-gewusel
                    
                    done()
                
                else done()
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
                
                    
        ##
        ##
        ##
        _display: (data, options, fn)->
        
            if (child = @children[0])._display
                child._display data, options, fn
                
            else
                fn?()
                        