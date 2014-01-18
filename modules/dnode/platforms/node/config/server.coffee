
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
            prepend: [require.resolve 'dnode/browser/bundle']
        
    ##
    children: [
    
        id: 'bridge'
        
        type: 'dnode.Bridge'
        
        data:
            parent: true
            
    ]
                            
        