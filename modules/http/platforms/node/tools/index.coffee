
formidable = require 'formidable'

module.exports =

    upload: (req, res, handler, done)->
    
        ##
        handler.data = data = 
            total: 0
            received: 0
            file: ''
    
        
        ## formidable - nothing more to say!
        
        
        ##
        form = formidable.IncomingForm()
                
        if handler.maxSize && parseInt(req.headers['content-length']) > handler.maxSize
            handler.error err = new Error 'limit exceeded'
            return done err
        
        form.uploadDir = floyd.system.appdir+'/.floyd/tmp/'
        
        curr = 0
        file = null
        sec = 0
        progress = ()=>    
            
            if handler.progress && data.total && data.file
                now = +new Date()
                data.progress = (parseInt data.received * 100 / data.total)
                
                if data.file isnt file || data.progress is 100 || data.progress >= curr + 5 || now > sec + 1000
                    
                    sec = now
                    curr = data.progress
                    file = data.file
                    
                    data.state = 'uploading'
                    
                    handler.progress data
     
     
        ## progress
        
        ##
        form.on 'fileBegin', (field, file)=>
    
            data.file = file.name
    
            progress()
                        
        
        ##
        form.on 'progress', (received, total)=>
            
            data.received = received
            data.total = total
            
            progress()
        
        
        ## collect files
        
        files = []
        
        ##
        form.on 'file', (field, file)=>
                    
            if file.type.match handler.accept
            
                files.push file
                
                if handler.file
                    handler.file 
                        name: file.name
                        size: file.size
                    , data, field
                
                progress()
            
            else                
                handler.error new Error 'invalid type:'+file.name
                
        
        ## fire!
        
        ##
        form.parse req, (err, fields)=>            
            done err, files, fields
        
        
    