
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
            #prepend: [require.resolve 'dnode/browser/bundle']
            
            node_modules: ['floyd/node_modules/shoe', 'floyd/node_modules/dnode']
            
            aliases: 
                dnode: '/node_modules/floyd/node_modules/dnode'
                shoe: '/node_modules/floyd/node_modules/shoe'
            
    ##
    children: [
    
        id: 'bridge'
        
        type: 'dnode.Bridge'
        
        data:
            parent: true
            
    ]
                            
        