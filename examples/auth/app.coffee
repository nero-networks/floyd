##
## auth demo...
##
## to run this demo successfull the following conditions must be met:
##
## 1. the private folder must be user/group readonly
##    try `chmod -R o-rwx ./private` (also done via floyd build)
##
## 2. the whole thing must be started as root
##    try `sudo floyd start`
##
##
## navigate to http://locathost:9036/ to try it out
##
## the password for test is asdf ;-)
##
##

try
    __SECRET = floyd.tools.files.read './private/secret.txt'
catch e
    console.warn e.message

module.exports = 

    new floyd.Config 'config.gui.server', 'config.dnode.server', 
        
        UID: 33
        GID: 33
        
        ##		
        data:
            port: 9036
            
            debug: true ## bloated scripts and html but faster startup
            
            rewrite:
                '^/((index.html)|(boot.js))?$': '/login/$1'
            
        
        ## some sanity checks on boot and on start.
        ## and loggings to point you with your nose into ;-)
        booted: ()->
            if process.getuid() isnt 0
                @logger.error new Error 'FATAL: you are not root! run sudo floyd start'
        
        ##
        started: ->			

            if _secret = floyd.tools.files.exists './private/secret.txt'
                @logger.error new Error 'FATAL: the file ./private/secret.txt is readable'
            
            if _users = floyd.tools.files.exists './private/users.data'
                @logger.error new Error 'FATAL: the file ./private/users.data is readable', if _secret then 'too!' else ''
            
            if !_secret && !_users
                @logger.info 'SUCCESS: userdata and secret are protected propperly.'
                 
        
        children: [
            
            ## 
            ## configure the users DB to readonly from file ./private/users.data
            ##
            
            ##
            id: 'users'
            
            ##
            data:
                readonly: true, debug: false, type: 'file', path: './private', name: 'users'
                
        ,
            
            ##
            ## add the backend client for protected access to __SECRET
            ##
            
            ##	
            id: 'test'			
            
            ## this method will be protected by the following permissionset
            secret: (fn)->
                
                fn null, __SECRET
                
            ##
            data:
                permissions: ## the permissionset to be used by Controllable._permitAccess 

                    ## only users with the role tester may access the method secret
                    secret:
                        roles: 'tester'			
                        
                        
        ,
            
            ##
            ## define a gui context for /login/ (rewritten from "/")
            ##
            
            type: 'gui.HttpContext'
            
            ##
            data:
                route: '/login/'
            
                file: '/index.html'
                
            ##
            remote:
                
                ##				
                type: 'dnode.Bridge'			
                            
                    
                ##
                children: [
                    
                    ##
                    id: 'login'
                    
                    ##
                    type: 'LoginForm'
                    
                ,	
                    
                    ##
                    type: 'gui.ViewContext'
                    
                    ##
                    template: ->
                        
                        button style:'display: none', 'click for secret'
                    
                    ##
                    wiring: ->
                    
                        @identity.on 'login', ()=>
                            @__root.show()
                        
                        @identity.on 'logout', ()=>
                            @__root.hide()
                
                        @__root.click =>
                            @lookup 'test', @identity, (err, test)->
                            
                                test.secret (err, secret)->
                                    return alert(err.message) if err
                                    
                                    alert secret		
                        
                ]
                
                        
                        
                        
        ]
    
            
