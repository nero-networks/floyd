
module.exports = 
    
    class ContactForm extends floyd.gui.ViewContext
    
        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config
                
                data:
                    #logger:
                    #    level: 'FINE'
                    
                    strings:
                        name: 'Name'
                        email: 'E-Mail'
                        subject: 'Betreff'
                        send: 'Abschicken'
                        next: 'weiter...'
                        message: 'Ihre Mitteilung an mich ...'
                        verify: 'Bitte überprüfen sie ihre Eingaben'
                        success: 'Ihre Nachricht wurde erfolgreich verschickt\nSie erhalten eine Kopie an Ihre E-Mail Adresse'
                        
                content: ->
                    
                    form class:'gui widgets ContactForm', action:'./sendMail', method:'post', ->
                        
                        
                        if location.query is 'ok'
                            p class:'hint success', -> @data.strings.success
                            
                        else
                        
                            p class:'hint'
                        
                            labeled_input = (name, text)->
                                label ->
                                    span (text+':')
                                    input name:name, value:''
                                    br()            
                            
                            labeled_input 'name', @data.strings.name            
                            labeled_input 'email', @data.strings.email                    
                            labeled_input 'subject', @data.strings.subject
                            
                            textarea name: 'message', placeholder: @data.strings.message
                            
                            div class:'buttons', ->
                                button class:'send', type:'submit', ->
                                    @data.strings.send
                        
                
                wiring: ->
                    
                    form = @find '.gui.widgets.ContactForm'
                    
                    hint = form.find '.hint'
                    button = form.find('button')
                    
                    parts = 
                        name: form.find '[name=name]'     
                        email: form.find '[name=email]'     
                        subject: form.find '[name=subject]'     
                        message: form.find '[name=message]'                                
                    
                    _reset = ()=>
                        hint.text('').attr 'class', 'hint'
                        
                        for part, ele of parts
                            ele.removeClass('verify')
                    
                    form.on 'submit', ()=>
                        
                        if hint.hasClass 'success'
                            location.reload()
                            
                        else
                            
                            _reset()
                                                    
                            data = {}
                            for part, ele of parts
                                data[part] = ele.val().trim()
                                
                            @lookup @data.find('mailer', @data.find 'origin'), @identity, (err, mailer)=>
                                return hint.addClass('error').text err.message if err
                                
                                mailer.sendMail data, (err, verify)=>
                                    return hint.addClass('error').text err.message if err
                                    
                                    if verify?.length
                                        hint.addClass('verify').text @data.strings.verify
                                        
                                        for part in verify
                                            parts[part].addClass 'verify'
                                
                                    else
                                        hint.addClass('success').text @data.strings.success
                                        
                                        for part, ele of parts
                                            ele.replaceWith ele.val()
                                            
                                        button.text @data.strings.next 
                                    
                        return false
                                    
            , config
        
        
                