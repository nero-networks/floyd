##
## Floyd Hello World 
##
## this module provides a context which says Hello World
##
## just add the following as a child to any context children array
## 
##		type: 'helloworld.HelloWorld'
##

module.exports = 
    
    ##
    ## @class floyd.helloworld.Context
    ## The HelloWorld context
    ##
    ## very simple so no configuration is needed
    ##
    class HelloWorld extends floyd.Context
    
        ##
        ## log the hello message on every context start
        ##
        ## @override
        start: (done)->
            super (err)=>
            
                if !err
                    ## this logs the message to the system console
                    @logger.info ' --> Hello World!!!'

                ## the done call is indispensable to 
                ## finally bring our parent-context up to live! 
                done err
            