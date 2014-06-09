
##
## sprintf() for JavaScript -> http://www.diveintojavascript.com/projects/javascript-sprintf
sprintf = require 'sprintf'

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
    ##
    ##
    isEmail: (str)->
    
        !!str.match /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
        
    
    ##
    ##
    ##
    sanitize: (str)->
        require('sanitizer').sanitize str
        

    ##
    ## UUID generator
    ## 
    ## nice hack from here
    ## http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript#answer-2117523
    ##  
    ##  i=0; start = +new Date()
    ##  
    ##  while (+new Date() - start) < 1000 && ++i
    ##     floyd.tools.strings.uuid_old()
    ##     
    ##  console.log i, 'UUIDs per second'
    ##
    ##  my firebug(acebug) console says: 
    ##  23368 UUIDs per second
    ##  23486 UUIDs per second
    ##  23502 UUIDs per second
    ##  23338 UUIDs per second
    ##
    uuid_old: ()->
        
        'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c)->
            r = Math.random()*16|0
            (if c is 'x' then r else r&0x3|0x8).toString(16)

    ##
    ## optimized UUID generator
    ## 
    ## improvement on the hack from here
    ## http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript#answer-2117523
    ##  
    ## look here
    ## http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/21963136#21963136
    ##
    ## i took Jeff Ward's e6() from here(http://jsfiddle.net/jcward/7hyaC/1/) on 24/02/2014 
    ## because it still had a slight increase on my desktop
    ##
    ##  i=0; start = +new Date()
    ##  
    ##  while (+new Date() - start) < 1000 && ++i
    ##     floyd.tools.strings.uuid_old()
    ##     
    ##  console.log j=i, 'UUIDs per second with uuid_old'
    ##
    ##  i=0; start = +new Date()
    ##  
    ##  while (+new Date() - start) < 1000 && ++i
    ##     floyd.tools.strings.uuid()
    ##     
    ##  console.log i, 'UUIDs per second with uuid'
    ##  console.log 'the new uuid is', (i / j).toFixed(2), 'times faster'
    ##
    ##
    ##  my firebug(acebug) console says: 
    ##   
    ##   26727 UUIDs per second with uuid_old
    ##   138970 UUIDs per second with uuid
    ##   the new uuid is 5.20 times faster
    ##   
    ##   26257 UUIDs per second with uuid_old
    ##   133505 UUIDs per second with uuid
    ##   the new uuid is 5.08 times faster
    ##   
    ##   28365 UUIDs per second with uuid_old
    ##   135616 UUIDs per second with uuid
    ##   the new uuid is 4.78 times faster
    ##   
    ##   28167 UUIDs per second with uuid_old
    ##   138498 UUIDs per second with uuid
    ##   the new uuid is 4.92 times faster
    ##   
    ##   26155 UUIDs per second with uuid_old
    ##   137794 UUIDs per second with uuid
    ##   the new uuid is 5.27 times faster
    ##
    uuid: ()->
        
        k = ['x','x','-','x','-','4','-','y','-','x','x','x']
        u = ''; i = 0; rb = Math.random()*0xffffffff|0
        while i++ < 12
            c = k[i-1]; r = rb&0xffff
            v = if c is 'x' then r else (if c is 'y' then (r&0x3fff|0x8000) else (r&0xfff|0x4000))
            
            u += if c is '-' then c else uuid_LUT[v>>8]+uuid_LUT[v&0xff]
            rb = if i&1 then rb>>16 else Math.random()*0xffffffff|0 
            
        return u

##
## helper table for uuid
##        
uuid_LUT = []
for i in [0..256]
    uuid_LUT[i] = (if i<16 then '0' else '')+i.toString(16)
            
