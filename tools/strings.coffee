
##
## sprintf() for JavaScript -> http://www.diveintojavascript.com/projects/javascript-sprintf
sprintf = require 'sprintf'

sanitizer = require 'sanitizer'

##
##
module.exports = 


    ##
    sprintf: sprintf.sprintf
    
    
    ##
    vsprintf: sprintf.vsprintf
    
    
    part: (str, split, idx)->
        list = str.split(split)
        
        if idx < 0
            idx = list.length + idx
        
        list[idx]
    
    ##
    tail: (str, num=1)->
        return if !str
        
        if (size = str.length) > num
            return str.substr size - num
        else
            return str
    
    ##
    capitalize: (str)->
        
        str.charAt(0).toUpperCase() + str.substr 1
    
    ##
    shorten: (str, len, append='...')->
        if str && str.length > len
            str = str.substr(0, len) + append
        return str	
    
    
    ## 
    ## simple string hashing function
    ##
    ## nice algorithm designed to implement Java's String.hashCode() method
    ## http://werxltd.com/wp/2010/05/13/javascript-implementation-of-javas-string-hashcode-method/
    ##
    hash: (str)->
        if typeof str isnt 'string'
            str = str.toString()
        
        hash = i = 0
        len = str.length # cache for efficiency
        while i < len
            hash = ((hash << 5) - hash) + str.charCodeAt(i++)
            hash = hash & hash
        
        return hash
    
    ##
    ## UUID generator
    ## 
    ## nice hack from here
    ## http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript#answer-2117523
    ##	
    ##	i=0; start = +new Date()
    ##	
    ##	while (+new Date() - start) < 1000 && ++i
    ##	   floyd.tools.strings.uuid()
    ##	   
    ##	console.log i, 'UUIDs per second'
    ##
    ##	my firebug(fireace) console says: 
    ##	23368 UUIDs per second
    ##	23486 UUIDs per second
    ##	23502 UUIDs per second
    ##	23338 UUIDs per second
    ##
    uuid: ()->
        
        'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c)->
            r = Math.random()*16|0
            (if c is 'x' then r else r&0x3|0x8).toString(16)
         
    
    ##
    ##
    ##
    isEmail: (str)->
    
        !!str.match /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
        
    
    ##
    ##
    ##
    sanitize: (str)->
        sanitizer.sanitize str