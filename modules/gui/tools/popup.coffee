
module.exports = (parent, config, fn)->
        
    if typeof config is 'function'
        fn = config
        config = {}
    
    if !fn
        fn = (err)=> 
            parent.logger.error(err) if err
            
    
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
    parent._createChild config, (err, child)=>
        return fn(err) if err
        
        child.boot (err)=>
            return fn(err) if err
            
            child.start (err)=>
                return fn(err) if err
                
                child.on 'cancel', ->
                    child.close()
                    
                child.on 'close', ->
                
                    child.__root.remove()
                    
                    child.stop ()-> 
                        #console.log 'stopped', child.ID
                        
                        parent.children.delete child
                        
                        child.destroy ()->
                        
                            #console.log 'destroyed', child.ID
    
                fn null, child
                
    