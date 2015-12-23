
module.exports = 

    class PubSubChat extends floyd.gui.ViewContext
        
        ##
        ##
        ##
        boot: (done)->		
            super (err)=>
                return done(err) if err

                @_display = @__root.find('> ul.display')
                @_users = @__root.find('> ul.users')
                @_input = @__root.find('> input')
                @_button = @__root.find('> button')
                
                @_input.keypress (e)=> 
                
                    if e.which is 13
                        @_button.click() 
                    
                        return false

                @_button.click ()=>

                    @_handle @_input.val(), (err)=>
                        return done(err) if err
                        @_input.val('')
                    
                    return false
                
                @_avatar = {}
                
                @lookup 'pubsub', @identity, (err, ctx)=>
                    return done(err) if err
                    
                    @_pubsub = ctx 
                    
                    done()

                                
        ##
        ##
        ##
        stop: (done)->
            if @_nick
                @_send disconnect: @_nick
            
            if @_token
                @_pubsub.unsubscribe @_token
        
            super done
        
        ##
        ##
        ##
        receive: (msg)->
            if msg

                msg.direct = true
                if msg.data.text.substr(0, 11) is '_ENCRYPTED_'
                    if (pass = prompt 'Verschlüsselte Nachricht von: '+msg.data.nick+'. Passworteingabe erforderlich.')
                        msg.data.text = floyd.tools.crypto.decrypt msg.data.text.substr(11), pass
                    
                @_receive null, msg
            

        ##
        ##
        ##
        _handle: (input, done)->
        
            if !@_nick
                @_connect input, done					
                                
            else if input.charAt(0) is '/'
                @_command input.substr(1), done
                
            else if input && @_nick
                @_send text: input, nick: @_nick, done
            
            else
                done()
        
        ##
        ##
        ##
        _send: (data, done)->
            data.avatar = @_avatar
            @_pubsub.publish data, done
        
        
        ##
        ##
        ##
        _command: (cmd, done)->
            
            args = cmd.split(' ')
            cmd = args.shift()
            
            if cmd is 'color'
                @_avatar.color = args.shift()
            
            else if cmd is 'clear'
                @_display.html ''
            
            else if cmd is 'help'
                @_display.append $('<li>').html """
                    /color - set css color for the nickname <br/>
                    /clear - clear message history
                """ 
                            
            else
                @_display.append $('<li>').text 'unknown command '+cmd
                
            done()
            
            
        
        ##
        ##
        ##
        _connect: (@_nick, done)->
            
            @_pubsub.subscribe (err, msg)=>
                
                if msg?.token
                    @_token = msg.token
                    
                    @_input.attr 'placeholder', 'message or /command'
                    @_button.text 'send'
                            
                    @_send connect: @_nick, respond: (err, user, origin)=>
                        if err
                            @_nick = null
                            @_pubsub.unsubscribe @_token
                            
                            @_users.find('li').remove()
                            
                            @_write 'join failed! your nick is already connected!'							
                            
                            @_input.attr 'placeholder', 'enter an alternate nick'
                            @_button.text 'join'
                            
                        else
                            @_addUser user, origin, true
                    
                    done()
                    
                else
                    @_receive err, msg

        
        ##
        ##
        ##
        _receive: (err, msg)->
            return console.error(err) if err
                    
            if data = msg.data 
                
                # receiving text message
                if text = data.text
                    nick = data.nick
                    
                    style = ''
                    if color = data.avatar.color
                        style += 'color:'+color+';'
                        
                    if msg.direct
                        style += 'font-style:italic;'
                    
                            
                    @_write '<b style="'+style+'">'+nick+'</b>: '+text
                
                
                # msg.origin is not myself
                if msg.origin isnt @ID
            
                    # user connection
                    if user = data.connect
                    
                        if user is @_nick
                            data.respond new Error 'already connected'
                    
                        else
                            @_addUser user, msg.origin
                            data.respond null, @_nick, @ID
                        
                                    
                    # user disconnection
                    if user = data.disconnect
                    
                        @_delUser user
    
        
        ##
        ##
        _write: (line)->
            @_display.append $('<li>').html line
            
            
        ##
        ##
        _addUser: (user, origin, quiet)->
            cls = _cls user
            
            if !@_users.find('.'+cls).length
                @_users.append $('<li>').text(user).addClass(cls).click ()=> 
                    @_sendPrivate user, origin
                    
                if !quiet
                    @_write user+' has joined the channel'
        
         
        ##
        ##
        _delUser: (user)->			
            if (ele = @_users.find '.'+_cls user).length
                @_write user+' has left the channel'
                ele.remove()
        
        ##
        ##
        _sendPrivate: (user, origin)->
                
            @lookup origin, @identity, (err, priv)=>
                return @error(err) if err
                
                _sendDirect = (text)=>                
                    priv.receive
                        origin: @ID
                        data:
                            text: text
                            nick: @_nick
                            avatar: @_avatar
                    
                
                floyd.tools.gui.popup @, 
                    view:
                        data:
                            user: user

                        content: ->
                            h1 'private message to: '+@data.user
                            textarea name:'text', rows:10, cols:50
                            br()
                            label 'Password (optional)'
                            input type:'password', name:'pass'

                    buttons:
                        content: ->
                            button class:'cancel', 'cancel'
                            button class:'send', 'send'
                              
                    events: 
                        send: ()->
                            text = @find('[name=text]').val()
                            
                            if (pass = @find('[name=pass]').val())
                                text = '_ENCRYPTED_'+floyd.tools.crypto.encrypt text, pass
                            
                            ## send direct
                            _sendDirect text
            
_cls = (str)->
    str.replace /[ .+]/g, ''