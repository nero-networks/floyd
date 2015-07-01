
module.exports =

    class Month extends floyd.gui.ViewContext

        ##
        ##
        ##
        configure: (config)->

            super new floyd.Config

                data:
                    class: 'Month'
                    browse:
                        class: 'browse'
                        titleClass: 'title'
                        prevText: '&laquo;'
                        prevClass: 'prev'
                        nextText: '&raquo;'
                        nextClass: 'next'
                
                content: ->

                    browseConf = @data.browse
                    div class:browseConf.class, ->
                        a class:browseConf.prevClass, href:'#', browseConf.prevText
                        span class:browseConf.titleClass
                        a class:browseConf.nextClass, href:'#', browseConf.nextText

                    table ->
                        thead ->
                            tr ->
                                for i in [1, 2, 3, 4, 5, 6, 0]
                                    th floyd.tools.date.moment.weekdaysMin[i]
                        tbody ->
                            for i in [0..5]
                                tr ->
                                    for j in [0..6]
                                        td()


            , config


        ##
        ##
        ##
        boot: (done)->
            super (err)=>
                return done(err) if err

                if date = @data.date then date = new Date date else date = new Date()
                
                date = floyd.tools.date.reset date, 1
                
                if $(@find('td')[0]).text()
                    @_currentMonth = date
                
                @_fill date
                
                done()
        
        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err
                
                @find('.'+@data.browse.class.join('.')+' >a').click (e)=>
                    date = new Date @_currentMonth
                    
                    date.setMonth date.getMonth() - if $(e.currentTarget).attr('class') is @data.browse.nextClass then -1 else 1

                    @_fill date
                    
                    @_emit 'browse',
                        date: new Date @_currentMonth
                        events: @_currentEvents

                    return false
                
                @find('td').click (e)=>
                    td = $(e.currentTarget)
                    
                    @_emit 'select',
                        date: new Date td.data 'date'
                        td: td
                
                ##    
                done()
                
                
        ##
        ##
        ##
        _wireEvents: ()->             
            @_getEvents @_currentMonth, (err, events)=>
                return @error(err) if err
                
                @_currentEvents = events
                
                @find('td').each (i, td)=>
                    td = $(td)
                    date = td.data 'date'

                    if event = events[date]
                        event.date ?= date

                        td.data 'event', event

                        @_wireEvent td, event
                        
                        
        ##
        ##
        ##
        _wireEvent: (td, event)->
            
            td.addClass 'event'
            if event.title
                td.attr 'title', event.title
                        
                    
        ##
        ##
        ##
        _getEvents: (month, fn)->
            fn null, {}
            
                
            
        
        ##
        ##
        ##
        _fill: (date, current)->
            
            redraw = @_currentMonth?.getTime() isnt date.getTime()
            
            ## reset the browse-links base var
            @_currentMonth = new Date date ## we make a copy because the original will be modified!
            
            if (current ?= @data.current)
                current = new Date(current).getTime()            
            
            today = floyd.tools.date.reset new Date()
            now = today.getTime()
            
            @find('.'+@data.browse.class.join('.')+' .'+@data.browse.titleClass.join('.')).text (floyd.tools.date.format date, 'MMMM YYYY')

            (prev = new Date date).setMonth prev.getMonth() - 1
            (next = new Date date).setMonth next.getMonth() + 1

            prev = prev.getMonth()
            next = next.getMonth()
            
            if (days = date.getDay() - 1) is -1
                days = 6
                
            date.setDate date.getDate() - days
            
            for cell in @find 'tbody td'
        
                cell = $(cell).data 'date', time = date.getTime()
                
                day = date.getDate()
                
                if redraw
                    cell.removeAttr('class').html('')
                
                    if time is now
                        cell.addClass 'today'
                
                    if current && time is current  
                       cell.addClass 'current'
                
                    if date.getMonth() is prev
                        cell.addClass 'prev'
                    
                    if date.getMonth() is next
                        cell.addClass 'next'
                
                    cell.text day
                
                date.setDate day + 1
                
            if (row = @find('tbody tr').last()).find('td').first().hasClass 'next'
                row.css display: 'none'
            else
                row.css display: 'table-row'
            
            @_wireEvents()
        