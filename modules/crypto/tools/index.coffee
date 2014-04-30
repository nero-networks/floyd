
module.exports = 

    ##
    ##
    ##
    hash: (str, algo='SHA1')->
        
        floyd.tools.crypto.CryptoJS[algo](str).toString()
    
    
    ##
    ## @deprecated - far too weak...
    ##  
    password_old: (pass, salt)->
        crypto = floyd.tools.crypto
        
        if !salt
            salt = crypto.hash(floyd.tools.strings.uuid()+floyd.tools.strings.uuid()).toString()
            
        crypto.hash(pass+salt) + salt
    
         
    ##
    ##
    ##
    encrypt: (str, pass, cipher='AES')->
        crypto = floyd.tools.crypto
        CryptoJS = floyd.tools.crypto.CryptoJS
                
        CryptoJS[cipher].encrypt(str, crypto.hash(pass)).toString()
                 
   
    ##
    ##
    ##
    decrypt: (str, pass, cipher='AES')->
        crypto = floyd.tools.crypto
        CryptoJS = crypto.CryptoJS
            
        CryptoJS[cipher].decrypt(str, crypto.hash pass).toString CryptoJS.enc.Utf8
        