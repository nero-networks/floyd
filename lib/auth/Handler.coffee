
module.exports = 

    class AuthHandler
        
        ##
        constructor: (api)-> floyd.tools.objects.extend @, api 
            
        ##
        authorize: (token, fn)-> fn()
        
        ##
        login: (token, user, pass, fn)-> fn new Error 'login impossible' 
            
        ##
        logout: (token, fn)-> fn()
            
        ##
        authenticate: (identity, fn)-> fn()
