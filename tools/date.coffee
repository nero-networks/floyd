
DateFormat = require('dateformatjs').DateFormat

DateFormat.prototype.locale = 'de'

DateFormat.names.de = 
    era: 
        abbr: ['BC', 'AD']
        full: ['B.C.', 'A.D.']
    amPm: 
        abbr: ['AM', 'PM']
        full: ['A.M.', 'P.M.']
    month: 
        abbr: ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez']
        full: ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']
    day: 
        abbr: ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa']
        full: ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag']


FORMATCACHE = {}
    
_format = (f)->
    FORMATCACHE[f] ?= new DateFormat f

module.exports = 
    SECOND:	1000
    MINUTE:	60 * 1000
    QUATER:	15 * 60 * 1000
    HOUR:	60 * 60 * 1000
    DAY:	24 * 60 * 60 * 1000
    
    names: DateFormat.names.de

    ##
    ## reset time to midnight
    ##
    reset: (date, day)->
        
        if day
            date.setDate day
        
        date.setMilliseconds 0
        date.setSeconds0 
        date.setMinutes 0 
        date.setHours 0 
            
        ##
        return date


    ##
    ##
    ##
    parse: (date, format='dd.MM.yyyy HH:mm')->		
        _format(format).parse if date instanceof Date then date else new Date date

    
    ##
    ##
    ##
    format: (date, format='dd.MM.yyyy HH:mm', split)->
        d = _format(format).format if date instanceof Date then date else new Date date
        
        if split
            d = d.split split
            
        return d
        
                