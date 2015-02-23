
##
## Basic Authenticating Context
## 
## handles static, unencrypted PSKs.
## does not provide dynamic logins
##
module.exports =
    
    class AuthContext extends floyd.Context
        
        ##
        ##
        ##
        configure: (config)->
            
            ## a static token has to be of the length of 40 plus the key in @_TOKENS
            ## e.g. 8b804dd8-7a88-4142-8b33-913a586d67b4----backend so that the following comes true
            ## @_TOKENS['backend'] is '8b804dd8-7a88-4142-8b33-913a586d67b4----backend'
            
            @_TOKENS = config.tokens
            
            super config    
        
        ##
        ##
        ##
        authorize: (token, fn)->
            if !token
                @logger.warning 'AuthContext.authorize NO TOKEN'
                return fn new Error 'AuthContext.authorize NO TOKEN'

            if @_TOKENS && @_TOKENS[token.substr 40] is token
                fn()
            
            else
                
                fn new Error 'AuthContext.authorize unauthorized token'
        
        ##
        ##                console.log identity.id, 'super err', err
        
        ##
        authenticate: (identity, fn)->
            identity.token (err, token)=>
                if err || !token
                    @logger.warning 'AuthContext.authenticate NO TOKEN', identity.id
                    return fn(err || new Error 'AuthContext.authenticate NO TOKEN') 
            
                ##
                if @_TOKENS && @_TOKENS[token.substr 40] is token
                
                    @logger.debug 'found known Token, authenticate SUCCESS', identity.id 
                    
                    fn()
            
                else
                    fn new Error 'AuthContext.authenticate TOKEN NOT FOUND'
            
        
        ##
        ##
        ##
        login: (token, user, pass, fn)-> fn new Error 'login impossible' 
            
        ##
        ##
        ##
        logout: (token, fn)-> fn()
            
    