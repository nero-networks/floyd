
##
## 
##
module.exports =
    
    type: 'http.Server'
    
    ##
    data:
        authProxy: true
        
        lib:
            modules: ['dnode']
            
            node_modules: ['floyd/node_modules/reconnect-core', 'floyd/node_modules/shoe', 'floyd/node_modules/dnode']
            
            aliases: 
                'reconnect-core': '/node_modules/floyd/node_modules/reconnect-core'
                shoe: '/node_modules/floyd/node_modules/shoe'
                dnode: '/node_modules/floyd/node_modules/dnode'
            
    ##
    children: [
    
        id: 'bridge'
        
        type: 'dnode.Bridge'
        
        data:
            parent: true
            
    ]
                            
        