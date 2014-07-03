
module.exports = 
    SECOND:	1000
    MINUTE:	60 * 1000
    QUATER:	15 * 60 * 1000
    HOUR:	60 * 60 * 1000
    DAY:	24 * 60 * 60 * 1000
    WEEK:   7 * 24 * 60 * 60 * 1000
    MONTH:  30 * 24 * 60 * 60 * 1000
    YEAR:   365 * 24 * 60 * 60 * 1000
    
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
    format: (date, format='DD.MM.YYYY', split)->
        
        d = floyd.tools.date.moment(date).format format
        
        if split
            d = d.split split
            
        return d
        
    
    ##
    ##
    ##
    isToday: (date)->
        now = new Date()
        
        return now.getDate() is date.getDate() \
            && now.getMonth() is date.getMonth() \
            && now.getYear() is date.getYear()
        