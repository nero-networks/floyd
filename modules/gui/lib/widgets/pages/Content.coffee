
module.exports =
    
    class ContentContext extends floyd.gui.ViewContext
        
        configure: (config)->
        
            super new floyd.Config
                
                data:
                    adminnavi:
                        parent: '#header'
            
            , config
        
        
        
        ##
        ##
        wire: (done)->
            super (err)=>
                done(err)
                
                #console.log @identity.login(), floyd.system.platform, location.pathname
                
                if @identity.login() 
                    
                    path = location.pathname.substr(1).split('/')                        
                    path.pop()
                    
                    origin = @data.find 'origin'
                    
                    @lookup origin, @identity, (err, ctx)=>
                        return done(err) if err
                        
                        $(@data.adminnavi.parent).append ul = $('<ul class="adminnavi"/>')
                        
                        if @identity.hasRole ['admin', 'editor']
                        
                            ul.append $('<li><a href="#" class="edit">bearbeiten</a></li>').click ()=>
                                
                                @_openEditor ctx
                            
                                return false
                        
                        ul.append $('<li><a href="#">logout</a></li>').click ()=>
                            
                            @_getAuthManager().logout (err)=> location.reload()    
                            
                            return false
                        
                   
        

        ##
        ##
        ##
        _openEditor: (ctx)->
            
            ##
            ctx.readFile (err, data)=>
                                            
                return @logger.error(err) if err
                
                ##
                floyd.tools.gui.popup @, 
                
                    id: 'editor'
                    
                    data:
                       close: false
                    
                    buttons:
                        content: ->
                            button class: 'cancel', 'Abbrechen'
                            button class: 'save', 'Speichern'
                
                , (err, popup)=>                                    
                    
                    popup.append textarea = $('<textarea/>').val(data)
                    
                    popup.on 'cancel', -> location.reload()
            
                    popup.on 'save', (e)=>                    
                    
                        ctx.writeFile textarea.val(), (err)=>    
                                            
                            if err 
                                alert(err.message) 
                            
                            else location.reload()
                    
                                