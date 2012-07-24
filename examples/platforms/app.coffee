
##
## A Simple Floyd-Platforms Example
##
module.exports = 
    
    ## --> ./platforms/node/lib/PlatformTest.coffee
    type: 'PlatformTest'

    ##
    children: [
    
        ## 
        type: 'http.Server'
    
        ##
        data:
            port: 9034
    
        ## --> ./platforms/remote/lib/PlatformTest.coffee
        remote: 
            type: 'PlatformTest' 	
    
    ]
