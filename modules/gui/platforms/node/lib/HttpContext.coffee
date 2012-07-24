
## 

jsdom = require 'jsdom'

Url = require 'url'

files = floyd.tools.files

module.exports = 

    ##
    ##
    ##
    class GuiHttpContext extends floyd.http.Context
        
        ##
        ##
        ##
        configure: (config)->
            @_template ?= config.template
            
            super new floyd.Config
            
                data:
                    ctype: 'text/html'
            
            ,config


        ##
        ##
        ##
        start: (done)->
        
            @_model.remote.data = 
                origin: @ID
        
            super done

                
        ##
        ##
        ##
        _createContent: (req, res, fn)->
            super req, res, (err, content)=>
                return fn(err) if err
                
                res.cache?.etag()
                
                
                if !content
                    
                    if @_template
                        
                        (floyd.tools.gui.ck @_template)
                            format: @data.find('debug') 
                            req: req
                            res: res
                            context: @
                            
                        , (err, content)=>
                            return fn(err) if err
                            
                            @_processContent req, res, content, fn
                    
                    
                    else if (_public = @data.find('public')) 
                        
                        url = @data.file || req.url.split('?').shift()
                        
                        floyd.tools.http.files.resolve url, _public, (err, file)=>
                            return fn(err) if err
                            
                            if files.fs.lstatSync(file).isDirectory()
                                file = files.path.join file, @data.find 'index'
                             
                            files.fs.readFile file, 'utf-8', (err, content)=>
                                return fn(err) if err
                                
                                
                                @_processContent req, res, content, fn
                        
                else
                    @_processContent req, res, content, fn
                
                
        ##
        ##
        ##
        _processContent: (req, res, content, fn)->

            if @data.no_processing
                return fn null, content
            
            ##
            @_createLocalModel req, res, (err, model)=> 
                return fn(err) if err
                
                if !model
                    fn null, content
                    
                else
                    
                    ##
                    #start = +new Date()
                    @_createWindow req, content, (err, window)=>
                        #console.log 'create:', (+new Date()) - start
                        
                        return fn(err) if err
                        
                        ##
                        model = floyd.tools.objects.serialize model, (if @data.find('debug') then 4 else 0)
                        
                        ##
                        window.addEventListener 'unload', next = ()=>					
                            #console.log 'run:', (+new Date()) - start
                            
                            window.removeEventListener 'unload', next
                            
                            ## send the response
                            _dt = window.document._doctype?._fullDT || '<!DOCTYPE html>'
                            fn null, _dt+window.document.innerHTML
        
                            ## cleanup async!
                            process.nextTick ()=>
                                
                                ## release the jsdom-window into the pool
                                @_releaseWindow window	
        
                        
                        ## fire!
                        window.run "(#{__boot__})(#{model})"
            

        
        
        ##
        ##
        ##
        _createWindow: (req, template, fn)->

            ## TODO https
            prefix = 'http://'+req.headers.host
            
                
            scripts = [prefix+'/floyd.js']

            ##
            ##
            jsdom.env template, scripts, (err, window)=>
                
                if window
                
                    window.$('html > script').remove()
                    
                    window.location = Url.parse prefix+req.url
                    
                    window.console = console
                    
                    window.floyd = window.require 'floyd'
                    
                    window.floyd.system.platform = 'jsdom'	
                    
                    window.floyd.system.libdir = floyd.system.libdir
                    window.floyd.system.appdir = floyd.system.appdir
                    
                    window.floyd.tools.files = floyd.tools.files
                    
                    window.floyd.__parent = 
                        lookup: (name, identity, fn)=>						
                            @lookup name, identity, (err, ctx)=>
                                fn err, ctx
                                                    
                fn err, window
        


        ##
        ##
        ##
        _releaseWindow: (window)->
                
            window.require = null
            window.floyd = null
            
            window.close()
        



##
## remote code - gets serialized and evaluated into the jsdom window
##
                    
                            
__boot__ = (config)->
    
    trigger = (type)->
        (event = window.document.createEvent 'Event').initEvent type, true, true
        window.dispatchEvent event
    
    trigger 'load'
    
    ##
    floyd.init config, (err, ctx)->
        return console.error(err) if err
        
        
        stopped = !ctx.stop
        destroyed = !ctx.destroy
        
        next = (err)->
            console.error(err) if err
            
            if !stopped && stopped = true

                trigger 'unload'
                
                ctx.stop next
                
            else
                
                if !destroyed && destroyed = true

                    ctx.destroy()
        
        trigger 'beforeunload'
        
        next()
            
            
        