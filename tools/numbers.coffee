
module.exports = numbers =

    ##
    ##
    ##
    parse: (val)->
        if val.replace

            if val.match /.*[.].*[,].*/ ## DE decimal
                val = val.replace '.', '' 

            if val.match /.*[,].*[.].*/ ## US decimal (no comma seperated integers! sorry)
                val = val.replace ',', ''

            val = val.replace ',', '.'
            
        parseFloat val
         
        
    
    ##
    ##
    ##
    format: (val, _dp=2, def)->
        
        val ?= def || 0

        if !val.toFixed
            val = numbers.parse(val)
    
        if _dp
            val.toFixed(_dp).replace '.', ','
    
        else
            parseInt val
        
    ##
    ##
    ##
    toHex: (num, size)->
        s = num.toString(16).toUpperCase()
        while s.length < size
            s = "0" + s;
        return s;    
