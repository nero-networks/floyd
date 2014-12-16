
module.exports = events =
    
    ##
    ##
    ##
    getPageXY: (e)->
        if e.pageX
            return x: e.pageX, y: e.pageY
        
        if touch = (e.touches?[0] || e.changedTouches?[0] || e.originalEvent.touches?[0] || e.originalEvent.changedTouches?[0])
            return x: touch.pageX, y: touch.pageY
        
        return error: 'pageXY'
    
    ##
    ##
    ##
    getPageX: (e)->
        events.getPageXY(e).x
        

    ##
    ##
    ##
    getPageY: (e)->
        events.getPageXY(e).y
    
    ##
    ##
    ##
    rightButton: (e)->
        if e.which is 3 || e.button is 2
            return true
        return false
    