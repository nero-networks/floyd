
module.exports =

    class Table extends floyd.gui.widgets.List

        configure: (config)->
            super new floyd.Config

                data:
                    class: 'Table'

                    limit: -1

                    listSelector: 'tbody:first'

                    thead: true

                    title: null

                    fields: {}

                template: ->
                    table class:(@data.class+' floyd-loading')

                content: ->

                    if @data.title
                        caption @data.title

                    if @data.thead
                        thead ->
                            tr ->
                                order = @data.fields._order || floyd.tools.objects.keys @data.fields

                                for key in order
                                    continue if key.charAt(0) is '_' || !(data = @data.fields[key])

                                    attr =
                                        class:key

                                    if data.tooltip
                                        attr.title = data.tooltip

                                    th attr, data.title || data

                    tbody()

                widget: ->

                    data = @__data.fields
                    attrs = {}

                    if data._tooltip && @[data._tooltip]
                        attrs.title = @[data._tooltip]
                        
                    if data._class && @[data._class]
                        attrs.class = @[data._class]

                    tr attrs, ->

                        order = data._order || floyd.tools.objects.keys data

                        for key in order
                            continue if key.charAt(0) is '_' || !(field = data[key])
                            
                            if field.format
                                value = field.format @

                            else 
                                value = @[key]
                            
                            value = (value?.toString()) || ''
                                                        
                            td class:key, value

            , config
