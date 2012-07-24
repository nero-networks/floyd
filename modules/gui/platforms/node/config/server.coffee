
module.exports = 
    
    type: 'http.Server'
    
    data:
        
        lib:
            modules: ['gui']
            
            node_modules: ['floyd/node_modules/markdown']
            
            aliases: 		
                markdown: '/node_modules/floyd/node_modules/markdown'
                        
            
            prepend: [require.resolve 'floyd/modules/http/public/js/jquery-1.7.2.min.js']
    
