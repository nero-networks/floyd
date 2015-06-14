##
##
##
module.exports =
    
    type: 'dnode.cluster.Director'
    
    #data:
    #    logger:
    #        level: 'STATUS'

    children: [
        
        UID: 65534 
        GID: 65534 
        
        id: 'frontend'
        
        isWorker: true
        
        children: [
            
            new floyd.Config 'config.dnode.server', 'config.gui.server',
            
                id: 'server'
                                
                data:
                    debug: true
                    
                    #logger:
                    #    level: 'DEBUG'
        
                    rewrite: 
                        '^/((index.html)|(boot.js))?$': '/home/$1'                
                
                children: [
                    
                    id: 'users'
        
                    memory:
                        test:
                            roles: ["tester"]
                            ## try 'asdf'
                            pass: 'd6b09dd822468d9dcc3fbe6f1497bf83-SHA256-4-1000-360c87fe1ee6cc80c1afcded5079056e'
                            
                
                ,
                
                    type: 'gui.HttpContext'
                    
                    data:
                        route: '/home/'
                
                        file: '/index.html'
                    
                    remote:
                        
                        type: 'dnode.Bridge'
                        
                        data:
                            debug: true
                        
                        children: [
                    
                            type: 'gui.widgets.LoginBox'
                        
                            building: (done)->
                                @_test done
                            
                            wiring: ()->
                                @on 'login', ()=>
                                    @_test()
                                
                                $('#update').click ()=>
                                    @_test()
                            
                            _test: (done)->
                                @lookup 'backend.data', @identity, (err, backend)=>
                                    return done(err) if err

                                    backend.test (err, data)=>
                                        
                                        $('#date').text err?.message || data
                                        
                                        done?()
                        
                        ]
                ]
                        
        ]
    
    ,
    
        UID: 33
        GID: 33
        
        id: 'backend'
        
        isWorker: true
        
        children: [
            
            id: 'data'
            
            permissions: 
                test: 
                    roles: 'tester'
        
            test: (fn)->
                fn null, new Date()
            
        ]
        
    ]
    
                
               