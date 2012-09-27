
module.exports =

    class Table extends floyd.gui.widgets.List

        configure: (config)->
            super new floyd.Config

                template: ->
                    table class:(@data.class+' floyd-loading')

                data:
                    class: 'Table'

                    limit: -1

                    listSelector: 'tbody:first'
                    
                    thead: true
                    
                    title: null
                    
                    fields: {}
                    
                    content: ->

                        if @data.title
                            caption @data.title

                        if @data.thead
                            thead ->
                                tr ->
                                    order = @data.fields._order || floyd.tools.objects.keys @data.fields
                                    
                                    for key in order
                                        title = @data.fields[key]
                                        
                                        if title.title
                                            title = title.title
                                            
                                        th class:key, title

                        tbody()

                widget: ->
                    tr ->
                        
                        order = @__data.fields._order || floyd.tools.objects.keys @__data.fields
                        
                        for key in order
                            
                            if (format = @__data.fields[key].format)
                                value = format @
                                
                            else
                                value = @[key] || ''
                                
                            td class:key, value 

            , config

