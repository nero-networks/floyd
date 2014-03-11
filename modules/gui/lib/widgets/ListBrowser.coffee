
module.exports =
    
    class ListBrowser extends floyd.gui.ViewContext
        
        configure: (config)->
            super new floyd.Config
                
                data:
                    color: 'white'
                    
                    text:
                        first: '|&lt;'
                        left: '&lt;'
                        right: '&gt;'
                        last: '&gt;|'
                
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
            
            
            @find('a').each (i, link)=>
                link = $(link).click ()=>
                    process.nextTick ()=>
                        @_emit 'browse',
                            offset: data.limit * parseInt link.attr('href').match(/([0-9]+)\/$/)[1]   
                            limit: data.limit
                
                    return false

            done?()
            
        ##
        ##
        ##
        _createLink: (href, type, text, _class, img)->
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
                        
            if (data?.size || 0) / (data?.limit || 5) <= 1
                done?() 
            
            else
                curr = parseInt data.offset / data.limit
                                
                last = (data.size - (rest = data.size % data.limit)) / data.limit
                if rest is 0
                    last -= 1
                
                linkdepth = @data.linkdepth || 1
                href = location.pathname.split('/')
                href[linkdepth + 1] = ''
                
                href[linkdepth] = 0
                @__root.append @_createLink href.join('/'), 'first', @data.text.first, 'first', @data.imageLinks
                
                href[linkdepth] = if curr > 0 then curr - 1 else last 
                @__root.append @_createLink href.join('/'), 'left', @data.text.left, 'prev', @data.imageLinks
                
                @_process [0..last],
    
                    each: (i, next)=>
                        href[linkdepth] = i
                        
                        link = @_createLink href.join('/'), 'page', i + 1, 'page'
                    
                        if i is curr
                            link.addClass 'actual'
                        
                        @__root.append link
                        
                        next()
                    
                    done: (err)=>
                        return done?(err) if err
                        
                        href[linkdepth] = if curr < last then curr + 1 else 0 
                        @__root.append @_createLink href.join('/'), 'right', @data.text.right, 'next', @data.imageLinks
                        
                        href[linkdepth] = last 
                        @__root.append @_createLink href.join('/'), 'last', @data.text.last, 'last', @data.imageLinks
                        
                        if floyd.system.platform is 'remote'
                            @_wireLinks data, done
                                         
                        
                        
