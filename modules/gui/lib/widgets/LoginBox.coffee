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
                
                    p class:'hint'
                
                    form class:'login', action:'#', method:'post', ->
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
        boot: (done)->
            super (err)=>
                return done(err) if err
                
                @_hint = @find('.hint').attr style: 'display: none'
    
                ##
                @_logout = @find('form.logout').attr style: 'display: none'
            
                ##                
                @_login = @find('form.login').attr style: 'display: none'
            
                ##
                @identity.login (err, user)=>
                    (if user then @_logout else @_login).removeAttr 'style'
                    done() 
                
        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err
                
                ##
                @_logout.on 'submit', ()=>
                    
                    @_getAuthManager().logout (err)=>
                        return @_onError(err) if err
                        
                        @_onLogout()
                        
                
                    return false                    
                
                ##                
                @_login.on 'submit', ()=>
                    pwfield = @find('[name=pass]')
                    if (login = @find('[name=login]').val()) && (pass = pwfield.val())
                                                        
                        @_getAuthManager().login login, pass, (err)=>
                            pwfield.val ''
                            
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
            
            @_hint.hide()
            
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
            @_hint.addClass('error').text(err.message).removeAttr 'style'
            