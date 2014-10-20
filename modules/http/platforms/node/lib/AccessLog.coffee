
morgan = require 'morgan'
cron = require 'cron'

##
##
##
module.exports = 
    
    class AccessLog extends floyd.Context
    
        configure: (config)->
            
            super new floyd.Config
                
                data:
                    format: 'combined'
                    file: '.floyd/logs/access.log'
                    
                    skip: (req)->
                        return false
                    
                    rotate:
                        cron: '* * 0 * * *'
                        files: 10
                        compress: true
                
                permissions: false
                    
                    
            , config
            
            
        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err
                
                _skip = (req)=>
                    @data.skip.apply @, [req]
                
                stream = floyd.tools.files.fs.createWriteStream @data.file, flags: 'a'
            
                logger = morgan @data.format, 
                    stream: stream
                    skip: _skip
                
                @delegate '_addMiddleware', (req, res, next)=>
                    logger req, res, next
                
                if @data.rotate
                    __cache = []
                    _cacheLogger = (req, res, next)=>
                        __cache.push [req, res, next]
                    
                    files = floyd.tools.files
                    zlib = require('zlib')
                    
                    job = new cron.CronJob @data.rotate.cron, ()=>
                    
                        logger = _cacheLogger
                        
                        ## close current write stream
                        stream.write '\n'
                        stream.close()
                        
                        ## rename current file to .old
                        files.mv @data.file, @data.file+'.old'
                        
                        ## open new stream
                        stream = files.fs.createWriteStream @data.file, flags: 'a'
                        
                        ## create logger with new stream
                        logger = morgan @data.format, 
                            stream: stream
                            skip: _skip
                        
                        while __cache.length > 0
                            logger.apply null, __cache.shift()
                        
                        ## rotate files
                        for i in [@data.rotate.files-1..0] 
                            from = @data.file+'.'+i
                            if @data.rotate.compress
                                from += '.gz'
                                
                            if files.exists from
                                if i+1 >= @data.rotate.files
                                    files.rm from
                                else
                                    to = @data.file+'.'+(i+1)
                                    if @data.rotate.compress
                                        to += '.gz'
                                        
                                    files.mv from, to
                        
                        files.mv @data.file+'.old', @data.file+'.0'
                        
                        if @data.rotate.compress
                            files.gzip @data.file+'.0'
                            
                    job.start()
                    
                done()
        