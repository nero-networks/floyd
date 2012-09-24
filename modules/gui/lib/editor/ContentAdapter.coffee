
module.exports =
    
    class ContentAdapter extends floyd.Context
        
        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config 
                
                data:
                    defaults:
                        type: 'gui.editor.Editor'
                
            , config
        
        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err
                
                @_loadUser (err, user)=>
                    @_adapt @parent, user, done
        
        ##
        ##
        ##
        _loadUser: (fn)->
            @identity.data fn
          
                    
        ##
        ##
        ##	
        _adapt: (ctx, user, done)=>        
            
            @_process ctx.children, 
                done: done
                
                each: (child, next)=>

                    if child.data.editor
                        editor = new floyd.Config @data.defaults, child.data.editor
                        
                        @_hasRole user, editor.roles, (err, ok)=>
                        
                            if ok
                                child._createChild editor
                            
                    
                    @_adapt child, user, next
                    
            
        ##
        ##
        ##            
        _hasRole: (user, roles, fn)->
            
            if roles 
                
                if user?.roles
                    for role in user.roles
                        if roles.indexOf(role) isnt -1
                
                            return fn null, true
            
                fn null, false
            
            else
                fn null, true
            
            