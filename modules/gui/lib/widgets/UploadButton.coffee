
module.exports =

    class UploadButton extends floyd.gui.ViewContext
    
        configure: (config)->
            config = super new floyd.Config
                template: ->
                    div class:'upload Button floyd-loading', style: 'display:inline-block'
                    
                data:
                    multiple: false
                    fields: {}
                    
                    selector: '.upload.Button'
                    action: './upload/'
                    
                    button:
                        text: 'hochladen'
                    
                        class: 'button'
                    
                content: ->                    
                    form action:@data.action, target:'upload-frame-'+@id, method:'post', enctype:'multipart/form-data', style: 'width:0;height:0;visibility:hidden', ->
                        
                        for name, field of @data.fields
                            
                            if !field || !(typeof field is 'object')
                                field = 
                                    value:field||''
                                    
                            input type:(field.type||'hidden'), name:name, value:(field.value)
                        
                        _attr = 
                            class: 'files'
                            type: 'file'
                            name: 'files'
                            style: 'width:0;height:0;visibility:hidden'
                            
                        if @data.multiple
                            _attr.multiple ='multiple'
                            
                        input _attr
                    
                    _attr = 
                        class:@data.button.class
                        
                    if _title = @data.button.title
                        _attr.title = _title
                        
                    if @data.button.type is 'link'
                        _attr.href = '#'
                        a _attr, (@data.button.html || @data.button.text)
                    
                    else
                        button _attr, (@data.button.html || @data.button.text)
                    
                    iframe id:'upload-frame-'+@id, name:'upload-frame-'+@id, width:'0px', height:'0px', frameborder:0, style: 'width:0;height:0;visibility:hidden'
                    
                    
                popup: 
                    
                    data:
                        class: 'info narrow'
                        close: false                                            
                    
                    view:
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
        wire: (done)->
            super (err)=>
                return done(err) if err
                                
                form = @find('form')

                files = form.find '[name=files]'                    
                
                @find('.'+@data.button.class).click ()=> 
                    files.click()
                    return false    
                
                files.change ()=>
                    
                    if files.val()
                        
                        @_prepareUpload files, (err)=>
                            return alert(err.message) if err
                        
                            @_backend (err, ctx)=>
                                
                                floyd.tools.gui.popup @, @_popup, (err, progress)=>                                
                                    
                                    ctx.registerUpload @_prepareHandler
                                    
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
                                                #location.reload()
                                            
                                            else if (parts = msg.split(':'))[0] is 'invalid type'
                                                alert 'Der Dateityp wurde nicht akzeptiert: '+parts[1]
                                                #location.reload()
                                                
                                            else
                                                @error new Error err.message
                ##  
                done()  
        
        
        ##
        ##
        ##
        _backend: (fn)->
            @_getBackend fn
            
        ##
        ##
        ##
        _prepareHandler: (handler)->
            return handler
        
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