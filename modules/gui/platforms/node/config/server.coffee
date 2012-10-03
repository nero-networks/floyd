
module.exports = new floyd.Config 
    
    type: 'http.Server'
    
    data:
        public: ['./public', floyd.system.libdir+'/modules/gui/public/']
        
        lib:
            modules: ['gui', 'http']
            
            node_modules: ['floyd/node_modules/markdown']
            
            aliases: 		
                markdown: '/node_modules/floyd/node_modules/markdown'
                        
            
            prepend: [
                floyd.system.libdir+'/modules/gui/public/js/jquery-1.7.2.min.js'
                floyd.system.libdir+'/modules/gui/public/js/jquery_single_double_click.js'
            ]
    
  