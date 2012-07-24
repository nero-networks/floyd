
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
                
                @_input.keypress (e)=> @_button.click() if e.which is 13

                @_button.click ()=>

                    @_handle @_input.val(), (err)=>
                        return done(err) if err
                        @_input.val('')
                
                @_avatar = {}
                
                ## TODO: hardcoded lookup origin (2x)
                @lookup 'chat.pubsub', @identity, (err, ctx)=>
                    return done(err) if err
                    
                    @_pubsub = ctx 

                                
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
                            
                    failed = false			
                    @_send connect: @_nick, respond: (err, user, origin)=>
                        if err
                            @_nick = null
                            @_pubsub.unsubscribe @_token
                            
                            @_users.find('li').remove()
                            
                            @_write 'join failed! your nick is already connected!'							
                            
                            @_input.attr 'placeholder', 'enter an alternate nick'
                            @_button.text 'join'
                            
                        
                        else if !failed
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
                
                ##
                ## text message
                if text = data.text
                    nick = data.nick
                    
                    style = ''
                    if color = data.avatar.color
                        style += 'color:'+color+';'
                        
                    if msg.direct
                        style += 'font-style:italic;'
                    
                            
                    @_write '<b style="'+style+'">'+nick+'</b>: '+text
                
                
                ##
                ## user connection
                if (user = data.connect) && msg.origin isnt @ID
                    
                    if user is @_nick
                        data.respond new Error 'already connected'
                    
                    else
                        @_addUser user, msg.origin
                        data.respond null, @_nick, @ID
                        
                                    
                ##
                ## user disconnection
                if (user = data.disconnect) && msg.origin isnt @ID
                    
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
                    
                    if text = prompt 'enter private message for: '+user
                        
                        ## TODO: hardcoded lookup origin
                        @lookup 'chat.'+origin, @identity, (err, priv)=>
                            return console.error(err) if err
                            
                            priv.receive
                                origin: @ID
                                data:
                                    text: text
                                    nick: @_nick
                                    avatar: @_avatar
                    
                if !quiet
                    @_write user+' has joined the channel'
        
            
        ##
        ##
        _delUser: (user)->			
            if (ele = @_users.find '.'+_cls user).length
                console.log ele
                @_write user+' has left the channel'
                ele.remove()
            
_cls = (str)->
    str.replace /[ .+]/g, ''