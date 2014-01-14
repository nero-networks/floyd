
module.exports = 
    
    class NaviContext extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        boot: (done)->
            super (err)=>
                return done(err) if err
                
                @_getItems '/', (err, items)=>
                    console.log items
        
        ##
        ##
        ##
        _getItems: (path, fn)->
            
             @lookup 'docs', @identity, (err, ctx)=>
                return fn(err) if err
                
                ctx.getNaviItems path, fn
            
        