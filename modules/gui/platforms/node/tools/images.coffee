
im = require 'imagemagick'

module.exports = images = 
    
    ##
    ##
    ##
    convert: (args...)->
        im.convert.apply im, args
    
    ##
    ##
    ##
    fix_orientation: (file, done)->
        temp = floyd.tools.files.tmp()
        im.convert [file, '-auto-orient', temp], (err)=>
            return done(err) if err
            
            floyd.tools.files.mv temp, file
            images.info file, done
    
    ##
    ##
    ##
    resize: (dimensions, src, dest, done)->
        
        if typeof dimensions is 'string'
            dimensions = 
                full: dimensions
        
        ##
        _scale = (size, src, dest, next)->      
            setImmediate ()=>
                if typeof size is 'function'
                    size src, dest, next
            
                else            
                    im.convert [src, '-resize', size, dest], next
        
        data =
            src: dest
            thumbnails: {}
        
        floyd.tools.objects.process dimensions,
            done: (err)->
                return done(err) if err
                
                done null, data
        
            each: (name, dimension, next)->
                
                if !(typeof dimension is 'object')
                    dimension =
                        size: dimension
                        path: (dest, name, dimension)->
                            dest.replace /\.([a-zA-Z]+)$/, ('.'+name+'.$1')
                
                if name is 'full'
                    _dest = dest
                    
                else
                    if typeof (_dest = dimension.path) is 'function'
                        _dest = _dest dest, name, dimension
                        
                    data.thumbnails[name] = _dest
                    
                _scale dimension.size, src, _dest, next
                
    
    ##
    ##
    ##
    crop: (geometry, src, dest, done)->
        
        im.convert ['-crop', geometry, src, dest], done
    
    
    ##
    ##
    ##
    scale_geometry: (geometry, factor)->
        [width, parts] = geometry.split 'x'
        (list = parts.split '+').unshift width
        
        for i in [0..list.length-1]
            list[i] = Math.round parseInt(list[i]) * factor
        
        return floyd.tools.strings.vsprintf '%sx%s+%s+%s', list
    
    
    ##
    ##
    ##
    info: (file, fn)->
        
        im.identify file, fn
        
