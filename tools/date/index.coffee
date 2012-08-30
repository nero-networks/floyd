
module.exports = 
    SECOND:	1000
    MINUTE:	60 * 1000
    QUATER:	15 * 60 * 1000
    HOUR:	60 * 60 * 1000
    DAY:	24 * 60 * 60 * 1000
    
    ##
    ## reset time to midnight
    ##
    reset: (date, day)->
        
        if day
            date.setDate day
        
        date.setMilliseconds 0
        date.setSeconds 0 
        date.setMinutes 0 
        date.setHours 0 
            
        ##
        return date


    ##
    ##
    ##
    parse: (date, format='DD.MM.YYYY HH:mm')->		
        
        floyd.tools.date.moment(date, format).toDate()

    
    ##
    ##
    ##
    format: (date, format='DD.MM.YYYY HH:mm', split)->
        
        d = floyd.tools.date.moment(date).format format
        
        if split
            d = d.split split
            
        return d
        
                