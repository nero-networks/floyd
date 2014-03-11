module.exports =

    class CheckboxGroup extends floyd.gui.widgets.List
        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config

                data:
                    class: 'CheckboxGroup'

                widget: ->
                    attr =
                        type: 'checkbox'
                        name: @name
                        value: @value || 1
                        
                    if @checked
                        attr.checked = 'checked'

                    li ->
                        input attr
                        label @label || @name


            , config

        ##
        ##
        ##
        _prepare: (item, fn)->
            if typeof item is 'string'
                item =
                    name: item

            super item, fn

