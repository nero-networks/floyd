module.exports =
    
    class LoginBox extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        configure: (config)->
            
            super new floyd.Config
                    
                data:
                    labels:
                        login: 'username'
                        pass: 'password'
                        
                template: ->
                    div class: 'LoginBox floyd-loading'
                    
                content: ->
                    form class:'login', action:'#', ->
                        label ->
                            span @data.labels.login
                            input type:'text', name:'login', value:''

                        label ->
                            span @data.labels.pass
                            input type:'password', name:'pass', value:''
                        
                        button type: 'submit', 'login'
                        
                    form class:'logout', action:'#', ->
                        button type: 'submit', 'logout'
                        
            , config
                
        
        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err
                
                @_logout = @find('form.logout').hide()
                @_login = @find('form.login').hide()
                
                @identity.login (err, user)=>
                    
                    if user
                        @_logout.show().on 'submit', ()=>
                        
                            @_getAuthManager().logout (err)=>
                                return @_onError(err) if err
                                
                                @_onLogout()
                                
                        
                            return false                    
                    else
                    
                        @_login.show().on 'submit', ()=>
                            
                            if (login = @find('[name=login]').val()) && (pass = @find('[name=pass]').val())
                                                                
                                @_getAuthManager().login login, pass, (err)=>
                                    return @_onError(err) if err
                                    
                                    @_onLogin()
                            
                            return false
                
                    ##
                    done() 
                
        ##
        ##
        ##
        _onLogin: ()->
            @_login.hide()
            
            @_emit 'login'
            
            @_logout.show()

            
        ##
        ##
        ##
        _onLogout: ()->
            @_logout.hide()
            
            @_emit 'logout'
            
            @_login.show()
            
        ##
        ##
        ##
        _onError: (err)->
            alert(err.message)
            