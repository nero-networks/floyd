 
module.exports =

    ##
    ##
    ##
    create: (pass, options)->

        options = floyd.tools.objects.extend {}, floyd.tools.crypto.password._options, options
    
        salt = floyd.tools.crypto.CryptoJS.lib.WordArray.random floyd.tools.objects.cut options, 'saltSize'
    
        floyd.tools.crypto.password._hash pass, salt.toString(), options
    
     
    ##
    ##
    ##
    verify: (pass, hash)->
        data = hash.split '-'
        
        if data.length > 1
            _hash = floyd.tools.crypto.password._hash pass, data[0],
                hasher: data[1] 
                keySize: (parseInt data[2])
                iterations: (parseInt data[3])                
        
        else # old, deprecated password hash
            _hash = floyd.tools.crypto.password_old pass, hash.substr 40 
        
        hash is _hash                
        
       
    ##
    ##
    ##
    _options:
        saltSize: 16
        keySize: 4
        iterations: 1000
        hasher: 'SHA256'
        
        
    ##
    ##
    ##
    _hash: (pass, salt, options)->            
        options.hasher = floyd.tools.crypto.CryptoJS.algo[hasher = options.hasher]
        
        hash = floyd.tools.crypto.CryptoJS.PBKDF2(pass, salt, options).toString()
        
        floyd.tools.strings.sprintf '%s-%s-%d-%d-%s', salt, hasher, options.keySize, options.iterations, hash


