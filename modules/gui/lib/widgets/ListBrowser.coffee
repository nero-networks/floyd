
qs = require('querystring')

module.exports =
    
    class ListBrowser extends floyd.gui.ViewContext
        
        configure: (config)->
            super new floyd.Config
                
                data:
                    color: 'white'
                    
                    linkSelector: '> a'
                    
                    text:
                        first: '|&lt;'
                        left: '&lt;'
                        right: '&gt;'
                        last: '&gt;|'
                    
                    pages: true
                    maxima: true
                
                template: ->
                    div class:'browse'
                        
            , config
        
        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err
                
                @_wireLinks @parent.data, done
        
        ##
        ##
        ##
        _wireLinks: (data, done)->            
            @find(@data.linkSelector).each (i, link)=>
                link = $(link).click ()=>
                    href = link.attr('href')
                    
                    if search = @data.search
                        offset = qs.parse(href.split('?')[1])[search]
                    else
                        offset = href.match(/([0-9]+)\/$/)[1]   
                        
                    process.nextTick ()=>
                        @_emit 'browse',
                            offset: data.limit * parseInt offset
                            limit: data.limit
                
                    return false

            done?()
            
        ##
        ##
        ##
        _createLink: (offset, type, text, _class, img)->
            
            if search = @data.search
                href = location.pathname
                @__query ?= if location.search then qs.parse location.search.substr 1 else {}
                
                @__query[search] = ''+offset
                href = href+'?'+qs.stringify @__query
                
            else
                linkdepth = @data.linkdepth || 1
                @__href ?= location.pathname.split('/')
                @__href[linkdepth] = offset
                @__href[linkdepth + 1] = ''
                
                href = @__href.join '/'
                

            link = $('<a>').attr('href', href).attr 'class', 'link '+_class
            
            if !img
                link.html text
            else
                link.append $('<img class="icon" alt="'+text+'">').attr('src', '/img/arrow-'+@data.color+'-'+type+'.png')

            
            return link
        
        
        ##
        ##
        ##
        _display: (items, data, done)->
            @__root.html ''
                                
            if !data.limit || (data?.size || 0) / data.limit <= 1
                done?() 
            
            else
                curr = (data.offset||0) / data.limit
                                
                last = (data.size - (rest = data.size % data.limit)) / data.limit
                if rest is 0
                    last -= 1
                
                if @data.maxima
                    @__root.append @_createLink 0, 'first', @data.text.first, 'first', @data.imageLinks
                
                offset = if curr > 0 then curr - 1 else last 
                @__root.append @_createLink offset, 'left', @data.text.left, 'prev', @data.imageLinks
                
                @_process (if @data.pages then [0..last] else []),
    
                    each: (i, next)=>
                    
                        link = @_createLink i, 'page', ''+(i + 1), 'page'

                        if i is curr
                            link.addClass 'actual'
                        
                        @__root.append link
                        
                        next()
                    
                    done: (err)=>
                        return done?(err) if err
                        
                        offset = if curr < last then curr + 1 else 0 
                        @__root.append @_createLink offset, 'right', @data.text.right, 'next', @data.imageLinks
                        
                        if @data.maxima
                            @__root.append @_createLink last, 'last', @data.text.last, 'last', @data.imageLinks
                        
                        if floyd.system.platform is 'remote'
                            @_wireLinks data, done
                                         
                        
                        
