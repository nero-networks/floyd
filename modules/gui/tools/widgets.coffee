
module.exports =

    ##
    ##
    ##
    select:

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
                        option.attr selected: true


    ##
    ##
    ##
    checkbox:

        ##
        value: (ele, value)->
            if value is undefined
                return !!ele.attr 'checked'

            else if value
                ele.attr checked: true

            else
                ele.removeAttr 'checked'
