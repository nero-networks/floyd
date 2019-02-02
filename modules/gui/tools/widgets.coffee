
module.exports = tools =

    ##
    ##
    ##
    csv:
        wrap: (ele)->
            ele._val = ele.val ## save for reuse in values

            ele.val = (val)->
                tools.csv.values ele, val

            return ele

        values: (ele, values)->
            ele._val ?= ele.val ## only if not already defined

            if values is undefined  ## read
                ele._val().trim().split /[\s]?,[\s]?/

            else ## write
                if typeof values is 'string'
                    values = [values]

                ele._val values.join ', '

    ##
    ##
    ##
    select:
        wrap: (ele)->
            ele.val = (values)->
                tools.select.values ele, values

            return ele

        ##
        values: (ele, values)->
            if values is undefined  ## read
                values = []
                ele.find('option').each (i, option)=>
                    option = $ option
                    if !!option.attr 'selected'
                        values.push option.val()

                return values

            else ## write
                if typeof values is 'string'
                    values = [values]

                ele.children().each (i, option)=>
                    option = $ option
                    if values.indexOf(option.val()) != -1
                        option.attr selected: 'selected'


    ##
    ##
    ##
    checkbox:

        wrap: (ele)->
            ele.val = (value)->
                tools.checkbox.value ele, value

            return ele

        ##
        value: (ele, value)->
            if value is undefined
                return !!ele.attr 'checked'

            else if value
                ele.attr checked: 'checked'

            else
                ele.removeAttr 'checked'
