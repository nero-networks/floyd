
module.exports =

    ##
    ## 
    ##
    class FileStore extends floyd.stores.Store
    
        ##
        ##
        ##
        init: (options, done)->
            super options, (err)=>
                return done(err) if err
                
                _dir = options.path ? floyd.tools.files.path.join '.floyd', 'data', 'stores'
                
                if !floyd.tools.files.exists _dir
                    floyd.tools.files.mkdir _dir, 0o700
                    
                dataFile = floyd.tools.files.path.join _dir, options.name+'.data'
                
                try
                    @_memory = JSON.parse floyd.tools.files.read dataFile, 'utf-8', 
                
                catch err
                    console.warn dataFile, 'not found'
                    
                done()
                
                ## only persist if not readonly
                if !options.readonly
                    _persist = @persist
                    
                    @persist = (done)=>
                    
                        _indent = if options.find('debug') then 4 else 0
                        
                        try
                            floyd.tools.files.write dataFile, JSON.stringify(@_memory, null, _indent)
                        
                        catch err
                            if _indent
                                console.warn 'FileStore %s: data not written to file', dataFile
                        
                        _persist.apply @, [done]		
                    
        
        ##
        ##
        ##		
        get: (key, fn)->		
            super key, (err, entity)->
                fn err, floyd.tools.objects.clone(entity)
        
        ##
        ##
        ##		
        set: (key, entity, fn)->
                
            super key, floyd.tools.objects.clone(entity), fn
            