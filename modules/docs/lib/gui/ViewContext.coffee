
highlight = require('highlight.js')

module.exports =
    
    ##
    ## floyd.docs.gui.ViewContext
    ##
    class DocsViewContext extends floyd.gui.ViewContext
        
        
        ##
        ## configuring
        ##
        configure: (config)->            
            super new floyd.Config
                
                template: ->
                    section class:'DocsViewContext floyd-loading'
                
                content: ->
                    nav id:'navi', class:'floyd-loading'
                    
                    section class:'canvas', ->
                        ul()
                
                children: [
                    id: 'navi'
                    
                    type: 'gui.ViewContext'
                    
                    data:
                        items: (fn)=>
                            
                            fn null,
                                '/test': 'Test'
                    
                ]
                
            , config
        
        
        ##
        ## booting
        ##  
        boot: (done)->
            super (err)=>
                return done(err) if err
                
                #console.ctx = @
                
                @_list = @find('.canvas ul')
                
                _wire = ()=>
                    if floyd.system.platform is 'remote'
                        divs = @find('.code')
                        
                        divs.addClass('folded').click (e)=>
                            
                            ele = $ e.currentTarget
                            
                            if e.currentTarget is divs[0]
                                if ele.hasClass 'folded'
                                    divs.removeClass 'folded'
                                else
                                    divs.addClass 'folded'
                            
                            else 
                                if ele.hasClass 'folded'                            
                                    divs.addClass 'folded'
                                    ele.removeClass 'folded'
                                else
                                    ele.addClass 'folded'
                    
                    done()
                    
                        
                if !@_list.children().length
                    @_getContent '/lib/Context', (err, data)=>
                        return done(err) if err
                        
                        @_displayContent data, _wire
                        
                else _wire()
                 
        
        ##
        ##
        ##
        _displayContent: (data, done)->
                        
            @_process data.items, 
                each: (val, next)=>
                    if val.docsText.charAt(0) is '#'
                        item=$('<li><div class="doc"></div><div class="code"></div></li>')
                    
                        doc = ''
                        for line in val.docsText.split '\n'
                            doc += line.substr 2
                        
                        code = val.codeText.trimRight()
                    
                        floyd.tools.gui.md doc, (err, html)=>
                            item.find('.doc').html html
                            item.find('.code').html highlight.highlight('coffeescript', code).value                            
            
                        @_list.append item
                
                    next()
                    
                done: done
                    
                    
      
                
        
        ##
        ## _getContext
        ##
        _getContent: (path, fn)->

            @lookup 'docs.data', @identity, (err, ctx)=>
                return fn(err) if err
                
                #console.log ctx
                
                #ctx.keys (err, keys)->
                #    console.log keys 
                
                ctx.get path, fn
        
        
        ##
        ##
        ##
        _getNavi: (path)->
            
            @lookup 'docs.data', @identity, (err, ctx)=>
                return fn(err) if err
                
                #console.log ctx
                
                #ctx.keys (err, keys)->
                #    console.log keys 
                
                ctx.get path, fn
            
                