
module.exports = 
    
    class LoginForm extends floyd.gui.ViewContext
    
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
                    
                    minimized: false
                        
                        
                content: ->
                    
                    form method:'post', action:'#', class:'gui widgets LoginForm', ->
                                            
                        if !(user = @identity.login())
                            p class:'hint'
    
                            div (if @data.minimized then style:'display:none' else {}), ->
                                input name:'user', value:'', placeholder: @data.strings.user
                                                                        
                                input name:'pass', value:'', type:'password', placeholder:@data.strings.pass
                        
                        attr = 
                            type: 'submit'
                            name:'button'
                            class: if user then 'logout' else 'login'
                            
                        if cls = @data.button?.class || @data.button
                            attr.class = attr.class+' '+cls 
                        
                        title = if user then @data.strings.logout else @data.strings.login
                            
                        if @data.button?.title
                            attr.title = title
                            
                        button attr, ->
                            if !@data.button?.title
                                text title
            
            
            , config
        
        
        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err
                
                hint = @find '.hint'
    
                login = @find('form.gui.widgets.LoginForm')
                
                user = login.find('input[name=user]')    
                pass = login.find('input[name=pass]')
                
                div = login.find('> div')
                
                login.on 'submit', ()=>
                    
                    if @identity.login()
                        
                        @_getAuthManager().logout (err)=> location.reload()                                        
                        
                    else            
                        if div.is ':visible'                            
                            @_getAuthManager().login user.val(), pass.val(), (err)=>                                    
                                if err
                                    pass.val ''
                                    hint.addClass('error').text(err.message)
                             
                                else
                                    location.reload()
                        
                        else div.show()
                        
                    return false
                
                done()
                