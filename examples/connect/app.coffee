##
## A Connect Floyd-Webserver Example
##
## creates a connect driven Http-Server Context
## with public directory and response-time profiler
##

connect = require 'connect'
responseTime = require 'response-time'
serveStatic = require 'serve-static'

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
    booted: ->

        ## registers the responseTime middleware.
        ## writes header x-response-time
        @server.use responseTime()


        ## registers the nice connect static middleware
        @server.use serveStatic './public'
