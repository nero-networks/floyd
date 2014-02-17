
module.exports = 

    type: 'http.Server'
    
    data:
        port: 9088
        
        #logger:
        #    level: 'DEBUG'
            
    
    children: [
        
        id: 'users'
        
        memory:
            test: 
                roles: ["tester"]
                pass: '69e7f432d72cf62aeb134fec74467cf9c786d361184acf36b5b3c58cdff3ee8324b8d25023d7207c'
    
    ,
    
        type: 'omarpc.HttpContext'
        
        registry:
            Test: 'test'
    ,
    
        id: 'test'
        
        data:
            permissions: 
                secret:
                    roles: 'tester'         
        
        echo: (str, fn)->
            fn null, str
        
        secret: (fn)->
            fn null, 'Secret: 42'
            
    ]
    