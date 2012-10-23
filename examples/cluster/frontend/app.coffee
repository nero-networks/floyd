
SECRETS = floyd.tools.stores.read('auth', '../secrets.json')

module.exports = new floyd.Config 'config.gui.server', 'config.dnode.server',
    
    UID: 33 ## www-data
    GID: 33 ## www-data
    
    ##
    data:
        debug: true
        #logger: (level: 'DEBUG')
        
        port: 8030
    
    children: [
        
        id: 'bridge'
        
        data:
            ports: [
                port: 8031
            ]
    
    ,
    
        id: 'sessions'
        
        tokens: SECRETS.tokens
        
    
    ,
    
        id: 'users'
        
        memory: SECRETS.users
        
        
    ]
    
    
    ##	
    remote:
        
        ##
        type: 'dnode.Bridge'
        
        ##
        data:
            debug: true
        
        logout: ->
            @_getAuthManager().logout ()=>
            
                location.reload()
            
        ##
        started: ->
            
            console.floyd = @
            
            @identity.once 'login', ()=>
                
                display = $ 'input[name=display]'
                refresh = $ 'button[name=refresh]'
                
                @lookup 'backend.test', @identity, (err, ctx)=>
                    return @logger.error(err) if err
                    
                    refresh.click ()=>
                    
                        ctx.echo +new Date(), (err, data)=>
                            return @logger.error(err) if err
                            
                            display.val data
            
            if !@identity.login()
                    
                if (user=prompt('username')) && (pass=prompt('password'))

                    @_getAuthManager().login user, pass, (err)=>
                        
                        if err
                            alert 'login failed!'
                            location.reload()
                        
