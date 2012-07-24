
module.exports = 

    ##
    ##
    ##
    hash: (str, algo='SHA1')->
        
        floyd.tools.crypto.cryptojs[algo](str).toString()
    
    
    
    ##
    ##
    ##	
    password: (pass, salt)->
    
        if !salt
            salt = floyd.tools.crypto.hash(floyd.tools.strings.uuid()+floyd.tools.strings.uuid()).toString()
            
        floyd.tools.crypto.hash(pass+salt).toString() + salt
    
         
        
        