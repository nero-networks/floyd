
module.exports = (parent, config, fn)->
    
    ##
    if typeof view is 'function'
        fn = view
        view = {}
    
    if typeof config is 'function'
        fn = config
        config = {}
    
    if !fn
        fn = (err)=> 
            parent.logger.error(err) if err
            
    
    ##
    _id = floyd.tools.objects.cut(view, 'id') || config?.id || parent.__ctxID()
    
    ##
    ##
    config = new floyd.Config 
            
        id: _id
        
        type: 'gui.ViewContext'
        
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
                    
        
        append: (ele)->
            @find('.body').append ele
        
        
        close: (fn)->
            @_emit 'close'
            fn?()
            
    , config

    
    ##
    ##
    parent._createChild config, (err, child)=>
        return fn(err) if err
        
        child.boot (err)=>
            return fn(err) if err
            
            child.start (err)=>
                return fn(err) if err
                
                fn err, child
                
                child.on 'cancel', ->
                    child.close()
                    
                child.on 'close', ->
                
                    child.__root.remove()
                    
                    process.nextTick ()->
                        child.stop ()-> 
                            #console.log 'stopped', child.ID
                            
                            parent.children.delete child
                            
                            child.destroy ()->
                            
                                #console.log 'destroyed', child.ID
        
            