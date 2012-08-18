
formidable = require 'formidable'

module.exports =

    upload: (req, handler)->
    
        ##
        handler.data = data = 
            total: 0
            received: 0
            file: ''
    
        
        ## formidable - nothing more to say!
    
        ##
        form = formidable.IncomingForm()
        
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
                    
                    handler.progress data
     
     
        ## handler
        
        ##
        form.on 'file', (field, file)=>
            
            handler.file? file, field, data
            
            progress()
            
        
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
        
        
        ## fire!
        
        ##
        form.parse req, (err, fields, files)=>
                
            handler.done? err, fields, files
        
        
    