
##
##
##
module.exports = 
    
    type: 'http.Server'
    
    data:
        public: [floyd.system.libdir+'/modules/gui/public/']
        
        lib:
            modules: ['gui', 'crypto']
            
            node_modules: ['floyd/node_modules/markdown', 'floyd/node_modules/sanitizer']
            
            aliases: 		
                markdown: '/node_modules/floyd/node_modules/markdown'
                sanitizer: '/node_modules/floyd/node_modules/sanitizer'
                        
            
            prepend: [
                floyd.system.libdir+'/modules/gui/public/js/jquery-1.7.2.min.js'
                floyd.system.libdir+'/modules/gui/public/js/jquery_single_double_click.js'
                floyd.system.libdir+'/modules/gui/public/js/jquery.highlight-3.min.js'
            ]
    