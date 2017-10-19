
module.exports =

    ##
    ## @class floyd.error.Exception
    ##
    class Exception extends Error

        name: 'floyd.error.Exception'
        title: 'Internal Server Error'

        constructor: (message, status)->
            super message
            @message = message||'Unknown Error'
            @status = status||500
            if Error.captureStackTrace
                Error.captureStackTrace @

            if @stack
                lines = @stack.split 'at '

                if lines[1]
                    cls = lines[1].split(' ')[0].split '.'

                else
                    cls = 'unknown'

                @stack = floyd.tools.strings.sprintf 'Error %s - %sat %s', @status, lines[0], lines.slice(cls.length+1).join('at ')
