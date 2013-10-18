
module.exports = 
    
    class ContactForm extends floyd.gui.ViewContext
    
        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config
                
                data:
                    
                    strings:
                        user: 'Benutzername'
                        pass: 'Password'
                        login: 'Login'
                        logout:'Logout'
                        
                        
                content: ->
                    
                    form class:'gui widgets LoginForm', ->

                        p class:'hint'
                        
                        user = @identity.login()
                        
                        if !user
                            input name:'user', value:'', placeholder: @data.strings.user
                                                                        
                            input name:'pass', value:'', type:'password', placeholder:@data.strings.pass
                        
                        button type: 'submit', name:'button', ->
                            if user then @data.strings.logout else @data.strings.login
            
            
                running: ->
                
                    hint = @find '.hint'
        
                    login = @find('form.gui.widgets.LoginForm')
                    
                    user = login.find('input[name=user]')    
                    pass = login.find('input[name=pass]')
                                                
                    login.on 'submit', ()=>
                        
                        if @identity.login()
                            
                            @_getAuthManager().logout (err)=> location.reload()                                        
                            
                        else            
                                                
                            @_getAuthManager().login user.val(), pass.val(), (err)=>                                    
                                if err
                                    pass.val ''
                                    hint.addClass('error').text(err.message)
                                 
                                else
                                     location.reload()
                         
                        return false
            
            , config
        
        
                