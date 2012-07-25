

module.exports = 

    class ViewContext extends floyd.Context
        
        ##
        ##
        ##
        configure: (config)->
            @_template ?= config.template
            
            floyd.tools.objects.intercept @, 'boot', (done, boot)=>
               
                @_build (err)=>
                    return done(err) if err
                    
                    boot done
                
            
            super new floyd.Config
            
                data: 
                    selector: undefined
                    
                    elements:
                        root: '<div class="floyd-loading"/>'
                    
            , config
        
        
        ##
        ##
        ##
        find: ()->
            @__root.find.apply @__root, arguments
        
        
        
        ##
        ##
        ##
        _build: (done, stage=0)->
            
            #@logger.info 'booting stage', stage
            
            ##
            ## get the root element to represent the context
            if stage is 0
                
                ## element is already there, found by selector -> stage 1
                if @data.selector && ( @__root = $ @data.selector, @parent?.__root ).length
                    
                    @_build done, 1
                
                ## or by id -> stage 1
                else if ( @__root = $ '#'+@id, @parent?.__root ).length
                    
                    @forIdentity @identity, (err, ctx)=>
                        @__root.data 'floyd', ctx
                    
                    @_build done, 1
                
                ## render root element, append to parent and recurse @_build
                else 
                
                    @_create (err, ele)=>
                        return done(err) if err
                        
                        if @parent?._append 
    
                            @parent._append ele, (err)=>
                                return done(err) if err
                                
                                @_build done, stage
                        
                        else
                            $('body').append(ele) if ele
                    
                            @_build done, stage
                            
            ##
            ## create content
            else if stage is 1
                
                if @__root.hasClass 'floyd-loading'
                    
                    @_emit 'loading'
                    
                    @_refresh (err)=>
                        return done(err) if err

                        @__root.removeClass 'floyd-loading'
        
                        @_emit 'loaded'

                        @_build done, stage
                            
                else
                    @_build done, 2
            
            ## stage 2 -> ready
            else
                
                done()

                
        ##
        ##
        ##
        _create: (fn)->
            
            next = (err, data)=>
                
                if data
                    ele = $(data)
                
                    if !ele.attr('id')
                        ele.attr 'id', @id
                    
                fn err, ele
            
            if typeof @_template is 'function'
            
                (floyd.tools.gui.ck @_template)
                    format: @data.find('debug') 
                    context: @						
                
                , next
                
            else
                next null, (@_template ? @data.elements.root)


        ##
        ##
        ##
        _append: (ele, fn)->			
            
            @__root.append(ele) if ele
            
            fn?()
        
        
        ##
        ##
        ##
        _refresh: (fn)->

            @_load (err, data)=>

                return fn(err) if err or !data
                
                @_update data, fn
                
        
        ##
        ##
        ##
        _load: (fn)->
            
            if typeof @data.content is 'function'
                
                if @data.raw
                    @data.content.apply @, [fn]
                
                else
                    (floyd.tools.gui.ck @data.content)
                        format: @data.find('debug') 
                        context: @											
                    , fn
                    
                
            else if !@data.raw
                floyd.tools.gui.md @data.content, fn

            else
                fn null, @data.content
        ##
        ##
        ##
        _update: (data, fn)->		

            @_append data, fn
