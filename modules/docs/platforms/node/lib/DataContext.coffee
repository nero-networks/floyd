
docco = require 'docco'

module.exports =
    
    class DataContext extends floyd.stores.Context
         
        ##
        ## configure
        ##
        configure: (config)->
            
            super new floyd.Config
                
                data:
                    path: floyd.system.libdir
                    exclude: [floyd.system.libdir+'/tmp', floyd.system.libdir+'/node_modules']
                    watch: true
                    
            , config
            
            
        ##
        ##
        ##
        boot: (done)->        
            super (err)=>
                return done(err) if err
                
                @_data = _ts: +new Date()
                
                @set '/', @_data
                
                @_initData @data.path, @_data, (err)=>
                    #console.log floyd.tools.objects.dump @_engine._memory
                    done err
                
        ##
        ##
        ##
        _initData: (path, data, done)->
        
            _files = floyd.tools.files
            
            dirs = []
            files = []
            
            for f in _files.fs.readdirSync path

                if f.charAt(0) isnt '.'
            
                    name = _files.path.join path, f
                    
                    if @data.exclude.indexOf(name) is -1
                    
                        if _files.fs.lstatSync(name).isDirectory f
                            dirs.push name
                        else
                            files.push name
            
            ##
            @_process dirs, 
        
                each: (dir, next)=>
                    key = dir.substr(@data.path.length)
                    
                    id = floyd.tools.strings.part(dir, '/', -1)
                    
                    @_initData dir, data[id]={}, ()=>
                        
                        if floyd.tools.objects.isEmpty data[id]
                            delete data[id]
                        else
                            @set key, data[id] 
                            
                        #console.log 'next', dir.substr(@data.path.length)
                        next()
            
                done: (err)=>
                    #console.log 'done dirs: ', dirs
                    return done(err) if err
                    
                    _id = (file)=>
                    __watch__ = (file, key, id)=>
                    
                    @_process files, 
                
                        each: (file, next)=>
                            return next() if !file.match /\.coffee$/ 
                            
                            id = floyd.tools.strings.part floyd.tools.strings.part(file, '/', -1), '.', 0
                            key = floyd.tools.strings.part file.substr(@data.path.length), '.', 0
                    
                            @_parseFile file, (err, content)=>                            
                                return done(err) if err
                                                                
                                @set key, data[id] = content
                            
                                next()
                            
                            if @data.watch
                           
                                floyd.tools.files.fs.watch file, (x)=>

                                    @_parseFile file, (err, content)=>                            
                                       return @_logger.error(err) if err
                                                                    
                                       @set key, data[id] = content
                                    
                        done: done 
        
        
        
        _parseFile: (file, fn)->
                        
            stat = floyd.tools.files.fs.lstatSync file
            
            data = 
                name: file.substr @data.path.lengths
                size: stat.size
                modified: stat.mtime
                items: []                
            
            floyd.tools.files.fs.readFile file, 'utf8', (err, raw)=>
                
                data.items = docco.parse '.coffee', raw
                    
            fn null, data
        