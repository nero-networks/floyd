
module.exports = (parent, config, fn)->
        
    if typeof config is 'function'
        fn = config
        config = {}
    
    if !fn
        fn = (err)=> 
            parent.error(err) if err && parent.error
            
    
    ##
    _id = config?.id || parent.__ctxID()
    
    ##
    ##
    config = new floyd.Config 
            
        id: _id
        
        type: 'gui.widgets.Popup'
            
    , config


    
    ##
    ##
    try
        parent._createChild config, (err, child)=>
            return fn(err) if err
            
            child.on 'cancel', ->
                child.fadeOut()
                
            child.on 'close', ->
            
                child.__root.remove()
                
                child.stop ()-> 
                    #console.log 'stopped', child.ID
                    
                    parent.children.delete child
                    
                    parent.once 'destroyed', ()->
                    
                        child.destroy ()->
                        
                            #console.log 'destroyed', child.ID
    
            fn null, child
    
    catch err
        alert err.message
