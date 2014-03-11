    
stylus = require 'stylus'
    
module.exports =

    class StylusContext extends floyd.Context
    
        configure: (config)->
            super new floyd.Config
                data:
                    route: '/styles.css'
                    file: '/public/styles.styl'
                    
            , config
        
        ##  
        ##  
        ##  
        start: (done)->
            super (err)=>
                return done(err) if err                
        
                @delegate '_addRoute', @data.route, (req, res, next)=>
        
                    res.ctype = 'text/css'
                    
                    res.cache.lastModified floyd.tools.files.stat(@data.file).mtime, ()=>
        
                        stylus(floyd.tools.files.read @data.file).render (err, style)=>
        
                            res.send style
                
                done()
                