
TOKEN = floyd.tools.stores.read('auth.tokens.backend', '../secrets.json')

module.exports =
    
    TOKEN: TOKEN
    
    UID: 65534 ## nobody
    GID: 65534 ## nogroup
    
    type: 'dnode.Bridge'
    
    data:
        debug: true
        #logger: (level: 'DEBUG')		
        
        authManager: 'frontend.sessions'

        gateways: [ ## frontend
            port: 8031
            reconnect: 2000
        ]
    
            
    
    children: [
    
        id: 'test'
        
        data:
            permissions:
                echo: 
                    roles: 'tester'
        
        echo: (inp, fn)->
            #console.log 'echo', inp, 'to', @echo.identity.id
            
            fn null, inp

    ]
    
        