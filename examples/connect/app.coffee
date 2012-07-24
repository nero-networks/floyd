##
## A Connect Floyd-Webserver Example
##
## creates a connect driven Http-Server Context
## with public directory and request-time profiler
##

connect = require 'connect'

##
module.exports = 
    
    ##
    type: 'http.Server'
    
    ##
    data:
    
        ##
        port: 9031

        ## this tells http.Server to call connect.createServer
        module: connect 
        
    
    ##
    ## hooks up to the livecycle booted event
    booted: ()->
            
        ## registers the responseTime middleware.
        ## writes header x-response-time
        @server.use connect.responseTime()

    
        ## registers the nice connect static middleware
        @server.use connect.static './public'
        
        