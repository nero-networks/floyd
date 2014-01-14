
module.exports = 
        
    new floyd.Config 'config.gui.server',  'config.dnode.server',
    
        data:
            port: 9037
            
            rewrite: 
                '^/((index.html)|(boot.js))?$': '/home/$1' 
                
            lib:
                modules: ['gui', 'http', 'docs', 'dnode']
                node_modules: ['floyd/node_modules/markdown', 'floyd/node_modules/highlight.js']
            
                aliases:        
                    markdown: '/node_modules/floyd/node_modules/markdown'
                    'highlight.js': '/node_modules/floyd/node_modules/highlight.js'
                
                
        
        children: [
            
            id: 'docs'
            
            type: 'docs.gui.HttpContext'
              
            remote:             
                
                type: 'dnode.Bridge'
            
                children: [
                    
                    id: 'container'
                    
                    type: 'docs.gui.ViewContext'
                    
                ]
        ]
                
    