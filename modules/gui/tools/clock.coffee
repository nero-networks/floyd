
##
module.exports =

    class Clock

        ##
        constructor: (@_ele, time, @_format)->
            @_format ?= 'DD.MM.YYYY HH:mm:ss'
            @reset time
            @start()

        ##
        reset: (time)->
            @_offset = if !time then 0 else (+new Date()) - time
            @_update()

        ##
        _update: ()->
            @_ele.text @format()

        ##
        format: ()->
            floyd.tools.date.format (+new Date()) + @_offset, @_format
        ##
        start: ()->
            @_interval = setInterval ()=>
                @_update()
            , 1000

        ##
        stop: ()->
            if @_interval
                clearInterval @_interval
                @_interval = null
