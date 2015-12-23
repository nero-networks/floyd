
qs = require('querystring')

module.exports =
    
    class ListBrowser extends floyd.gui.ViewContext
        
        configure: (config)->
            super new floyd.Config
                
                data:
                    color: 'white'
                    
                    wireLinks: true
                    linkSelector: '> a'
                    
                    text:
                        first: '|&lt;'
                        left: '&lt;'
                        right: '&gt;'
                        last: '&gt;|'
                    
                    pages: 5
                    
                    first: true
                    left: true
                    right: true
                    last: true
                    
                    followable: true
                
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
            return done() if !@data.wireLinks
            
            @find(@data.linkSelector).click (e)=>
                link = $ e.currentTarget
                
                href = link.attr('href')
                
                if search = @data.search
                    offset = qs.parse(href.split('?')[1])[search]
                else
                    offset = href.match(/([0-9]+)\/$/)[1]   
                    
                @_emit 'browse',
                    offset: data.limit * parseInt offset
                    limit: data.limit                
                
                return false

            done?()
            
        ##
        ##
        ##
        _createLink: (offset, type, text, _class, img, followable)->
            
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
            
            if !followable
                link.attr 'rel', 'nofollow' 
            
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
                
                if @data.first
                    @__root.append @_createLink 0, 'first', @data.text.first, 'first', @data.imageLinks
                
                if @data.left
                    offset = if curr > 0 then curr - 1 else last 
                    @__root.append @_createLink offset, 'left', @data.text.left, 'prev', @data.imageLinks
                
                if _pages = @data.pages
                    if _pages is true
                        _pages = last
                    
                    ##                    
                    
                    if (from = curr - Math.floor(_pages/2)) < 0
                        from = 0 
    
                    if (to = from + _pages-2) >= last
                        to = last

                    pages = [from..to]
                    
                    while pages.length < last && pages.length < _pages-1
                        pages.unshift pages[0]-1
                    
                    if to is last && pages.length < last
                        pages.unshift pages[0]-1
                    
                    ##
                       
                    #pages = [0.._pages]
                
                @_process (pages || []),
    
                    each: (i, next)=>
                        
                        followable = if @data.followable && !@data.right && i > 0 && i-1 is curr then true else false
                        
                        link = @_createLink i, 'page', ''+(i + 1), 'page', null, followable

                        if i is curr
                            link.addClass 'actual'
                        
                        @__root.append link
                        
                        next()
                    
                    done: (err)=>
                        return done?(err) if err
                        
                        if pages && pages.length < last && pages.length < _pages
                            if pages[pages.length-1]+1 < last
                                @__root.append '<span class="dots">..</span>'
                            
                            @__root.append @_createLink last, 'page', ''+(last + 1), 'page'
                            
                        
                        if @data.right
                            offset = if curr < last then curr + 1 else 0 
                            followable = !!(@data.followable && offset > 0)
                            @__root.append @_createLink offset, 'right', @data.text.right, 'next', @data.imageLinks, followable
                        
                        if @data.last
                            @__root.append @_createLink last, 'last', @data.text.last, 'last', @data.imageLinks
                        
                        if floyd.system.platform is 'remote'
                            @_wireLinks data, done
                                         
                        
                        
