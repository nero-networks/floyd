
module.exports =
    
    class ListBrowser extends floyd.gui.ViewContext
        
        configure: (config)->
            super new floyd.Config
                
                data:
                    color: 'white'
                
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
            _emit = (i)=>
                @_emit 'browse',
                    offset: i*data.limit
                    limit: data.limit
                return false
                        
            @find('a').each (i, link)=>
                link = $(link).click ()=>
                
                    _emit parseInt link.attr('href').match(/([0-9]+)\/$/)[1]        
            
            done?()
            
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
                
                linkdepth = @data.linkdepth
                href = location.pathname.split('/')
                href[linkdepth + 1] = ''
                
                href[linkdepth] = 0
                @__root.append $('<a>').attr('href', href.join '/')
                    .attr('class', 'link first')
                    .append($('<img class="icon" alt="|&lt;">').attr 'src', '/img/arrow-'+@data.color+'-first.png')
                
                href[linkdepth] = if curr > 0 then curr - 1 else last 
                @__root.append $('<a>').attr('href', href.join '/')
                    .attr('class', 'link prev')
                    .append($('<img class="icon" alt="&lt;">').attr 'src', '/img/arrow-'+@data.color+'-left.png')
                
                @_process [0..last],
    
                    each: (i, next)=>
                        href[linkdepth] = i
                        link = $('<a>').attr('href', href.join '/')
                            .attr('class', 'link page')
                            .text(i + 1)
                    
                        if i is curr
                            link.addClass 'actual'
                        
                        @__root.append link
                        
                        next()
                    
                    done: ()=>
                
                        href[linkdepth] = if curr < last then curr + 1 else 0 
                        @__root.append $('<a>').attr('href', href.join '/')
                            .attr('class', 'link next')
                            .append($('<img class="icon" alt="&gt;">').attr 'src', '/img/arrow-'+@data.color+'-right.png')
                         
                        href[linkdepth] = last 
                        @__root.append $('<a>').attr('href', href.join '/')
                            .attr('class', 'link last')
                            .append($('<img class="icon" alt="&gt;|">').attr 'src', '/img/arrow-'+@data.color+'-last.png')
                        
                        @_wireLinks data, done
                                         
                        
                        
