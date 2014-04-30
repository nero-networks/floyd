##
## O bject M ethod A rgs RpcServer Example
##
## try the following urls in your browser
##
## 1. http://localhost:9088/RpcServer?o=System&m=getInfo&a=[%22Test%22]
## 2. http://localhost:9088/RpcServer?o=Test&m=echo&a=[%22hallo%22]
## 3. http://localhost:9088/RpcServer?o=Test&m=secret&a=[]
## 4. http://localhost:9088/RpcServer?o=System&m=login&a=[%22test%22,%20%22asdf%22]
## 5. http://localhost:9088/RpcServer?o=Test&m=secret&a=[]
## 6. http://localhost:9088/RpcServer?o=System&m=logout&a=[]
##
module.exports = 

    type: 'http.Server'
    
    data:
        port: 9088
        
        #logger:
        #    level: 'DEBUG'
            
    
    children: [
        
        ## substitute the users db with data        
        id: 'users'
        
        memory:
            test:
                roles: ["tester"]
                pass: 'd6b09dd822468d9dcc3fbe6f1497bf83-SHA256-4-1000-360c87fe1ee6cc80c1afcded5079056e'
    
    ,

        ## setup a RpcServer context
        type: 'omarpc.HttpContext'
        
        registry:
            ## register the test Context as usable by the RpcServer
            Test: 'test'
    ,
                
        ## setup a simple Context with a protected method
        id: 'test'
        
        data:
            permissions: 
                secret:
                    roles: 'tester' 
        
        ## this method is public for everyone
        echo: (str, fn)->
            fn null, str
        
        ## only users with the tester role can access this method
        secret: (fn)->
            fn null, 'Secret: 42'
            
    ]
    