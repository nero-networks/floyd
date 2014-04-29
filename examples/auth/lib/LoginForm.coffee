
module.exports =

    ##
    ##
    ##
    class LoginForm extends floyd.gui.ViewContext
    
        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config
                
                template: ->
                    div ->
                        div class: 'login', ->
                            input name: 'user'
                            input name: 'pass', type: 'password'
                            
                            button name: 'login', 'login'
                        
                        div class: 'logout', style:'display: none', ->
                            
                            button name: 'logout', 'logout'
                        
            , config
        
        
        ##
        ##
        ##
        _update: ()->			
            
            logout = @find '> div.logout'		
            login = @find '> div.login'
            
            @identity.login (err, user)->
                
                if user
                    login.attr 'style','display: none'
                    logout.attr 'style', null
                
                else
                    logout.attr 'style','display: none'
                    login.attr 'style', null
                
        ##
        ##
        ##	
        start: (done)->
            super (err)=>
                
                @identity.on 'login', ()=>
                    @_emit 'login' ## announce the new status to listeners
                    @_update()
                
                @identity.on 'logout', ()=>
                    @_update()
                    @_emit 'logout'
                
                done()
                    
                
        ##
        ##
        ##  
        wire: (done)->
            super (err)=>
                
                user = @find 'input[name="user"]'
                pass = @find 'input[name="pass"]'
                
                @find('button[name="login"]').click ()=>
                        
                    # login to the application as user with pass
                        
                    @_getAuthManager().login user.val(), pass.val(), (err)=>

                        pass.val('') # always empty the passwd field
                        
                        if !err
                            user.val('') # for convinience leave user field until login succeeds
                        
                            
                        else alert err.message	
                        
                    ##
                    return false
        
        
                @find('button[name="logout"]').click ()=>
                    
                    @_getAuthManager().logout ()=>
                    
                        @_update()
                    
                    ##				
                    return false	
                
                
                    
                ##
                done()
                
                        