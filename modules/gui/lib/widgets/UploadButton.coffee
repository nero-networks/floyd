
module.exports =

    class UploadButton extends floyd.gui.ViewContext
    
        configure: (config)->
            config = super new floyd.Config
                template: ->
                    section class:'upload Button floyd-loading'
                    
                data:
                    multiple: false
                    fields: {}
                    
                    selector: '.upload.Button'
                    action: './upload/'
                    
                    content: ->                    
                        iframe id:'upload-frame', name:'upload-frame', width:'0px', height:'0px', frameborder:0
                        
                        form action:@data.action, target:'upload-frame', method:'post', enctype:'multipart/form-data', ->
                            
                            for name, field of @data.fields
                                
                                if !field || typeof field is 'string'
                                    field = 
                                        value:field||''
                                        
                                input type:(field.type||'hidden'), name:name, value:(field.value)
                            
                            if @data.multiple
                                input class:'files', type:'file', name:'files', multiple:'multiple'
                                
                            else
                                input class:'files', type:'file', name:'files'
    
                        a class:'button img-next link', href:'#', 'hochladen'
                    
                    
                popup: 
                    
                    data:
                        class: 'dialog narrow'
                        close: false                                            
                    
                    view:
                        data:
                            content: ->
                                section class:'upload Status', ->
                                    
                                    div class:'progress'
                                    
                                    div class:'info', ->
                                        span class:'name'
                                        span class:'value'
                                         
                    
                    update: (data)->
                    
                        value = data.progress+'%'
                        name = floyd.tools.strings.shorten(data.file, 50)
                        
                        @find('.progress').width value
                        
                        @find('.name').text name
                        @find('.value').text data.state+' '+value
                                
                                    
            , config
            
            @_popup = config.popup
            
            return config
        
        
        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err
                                
                form = @find('form')

                files = form.find '[name=files]'                    
                
                @find('.button').click ()=> 
                    files.click()
                    return false    
                
                files.change ()=>
                    
                    if files.val()
                        
                        @_prepareUpload files, (err)=>
                            return alert(err.message) if err
                        
                            @_backend (err, ctx)=>
                                
                                floyd.tools.gui.popup @, @_popup, (err, progress)=>                                
                                    
                                    ctx.registerUpload
                                    
                                        connect: ()=>
                                            @_connect (err)=>
                                                if !err
                                                    @_emit 'connect', files
                                                    
                                                    process.nextTick ()=>
                                                        form.submit()                                                  
                                                        files.val ''
                                             
                                        progress: (data)=>                            
                                            @_emit 'progress', data
                                            
                                            process.nextTick ()=>
                                                @_progress data, ()=>
                                                    progress.update data                                            
                                        
                                        disconnect: ()=>
                                            @_emit 'disconnect'
    
                                            progress.fadeOut null, ()=>
    
                                                @_disconnect()
                                        
                                        error: (err)=>
                                            if (msg = err.message) is 'limit exceeded'
                                                alert 'Zu viele Daten! Reduziere die Anzahl oder die Größe der Dateien.'
                                                location.reload()
                                            
                                            else if (parts = msg.split(':'))[0] is 'invalid type'
                                                alert 'Der Dateityp wurde nicht akzeptiert: '+parts[1]
                                                location.reload()
                                                
                                            else
                                                @error new Error err.message
                ##  
                done()  

        ##
        ##
        ##
        _prepareUpload: (files, fn)->
            if !@data.multiple && files[0].files.length > 1
                return alert 'Es kann nur eine Datei hochgeladen werden!'
                
            fn?()
            
        ##
        ##
        ##
        _connect: (fn)->
            fn?()
            
        
        ##
        ##
        ##
        _progress: (data, fn)->
            fn?()
            
        
        ##
        ##
        ##
        _disconnect: (fn)->
            fn?()