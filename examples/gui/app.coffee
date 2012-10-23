
module.exports =

    new floyd.Config 'config.gui.server',
    
        ##
        data:
            port: 9033
            
            rewrite: 
                '^/((index.html)|(boot.js))?$': '/home/$1'
        
        children: [
            
            type: 'gui.HttpContext'
            
            data:
                route: '/home/'
                
                file: '/index.html'
        
            ##	
            remote:				
                
                children: [
                    
                    type: 'gui.ViewContext'
                
                    content: 'Hello World!'
                
                ]
        ]
            