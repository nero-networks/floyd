 
module.exports = password =

    ##
    ##
    ##
    create: (pass, options, done)->

        if typeof options is 'function'
            done = options 
            options = null
        
        if done
            setImmediate ()->
                done null, password.create pass, options
            
        else    

            options = floyd.tools.objects.extend {}, floyd.config.crypto.password, options
    
            salt = floyd.tools.crypto.CryptoJS.lib.WordArray.random floyd.tools.objects.cut options, 'saltSize'
    
            password._hash pass, salt.toString(), options
    
     
    ##
    ##
    ##
    verify: (pass, hash, done)->
        if done
            setImmediate ()=>
                done null, password.verify pass, hash
            
        else    
	        data = hash.split '-'
	        
	        if data.length > 1
	            _hash = password._hash pass, data[0],
	                hasher: data[1] 
	                keySize: (parseInt data[2])
	                iterations: (parseInt data[3])                
	        
	        else # old, deprecated password hash
	            _hash = floyd.tools.crypto.password_old pass, hash.substr 40 
	        
	        hash is _hash                
                
        
    ##
    ##
    ##
    _hash: (pass, salt, options)->            
        options.hasher = floyd.tools.crypto.CryptoJS.algo[hasher = options.hasher]
        
        hash = floyd.tools.crypto.CryptoJS.PBKDF2(pass, salt, options).toString()
        
        floyd.tools.strings.sprintf '%s-%s-%d-%d-%s', salt, hasher, options.keySize, options.iterations, hash


