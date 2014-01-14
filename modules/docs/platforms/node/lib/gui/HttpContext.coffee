
module.exports =
    
    class DocsHttpContext extends floyd.gui.HttpContext
        
        ##
        ##
        ##
        configure: (config)->
            
            super new floyd.Config
                
                started: ->
                    @getNaviItems '/', (err, items)=>
                        console.log items
                
                data:
                    route: '/home/'
                
                    file: '/index.html'
                    
                children: [
                    
                    id: 'data'
                    
                    type: 'docs.DataContext'
                    
                    data:
                        path: floyd.system.libdir
                        
                ]
                
            , config
            
        
        ##
        ##
        ##
        getNaviItems: (path, fn)->
        
            @children.data.get path, (err, data)=>
                return fn(err) if err
                
                items = 
                    dirs: []
                    files: []
                
                for key, value of data
                    
                    if key.charAt(0) isnt '_'
                        if data.name && data.size && data.modified
                            items.files.push key
                        else
                            items.dirs.push key
                
                fn null, items
        
        