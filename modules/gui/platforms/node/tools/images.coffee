
im = require 'imagemagick'

module.exports = 

    resize: (dimensions, src, dest, done)->
        
        if typeof dimensions is 'string'
            dimensions = 
                full: dimensions
        
        ##
        _scale = (size, src, dest, next)->      
            
            im.convert [src, '-resize', size+'\>', dest], next
        
        
        floyd.tools.objects.process dimensions,
            done: done
        
            each: (name, size, next)->
                if name is 'full'
                    _dest = dest
                
                else
                    _dest = dest.replace /\.([a-zA-Z]+)$/, ('.'+name+'.$1')
                    
                _scale size, src, _dest, next
                
                