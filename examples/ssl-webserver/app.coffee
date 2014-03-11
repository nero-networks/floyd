
##
## A Simple Floyd HTTPS-Webserver Example
##
## creates a simple Https-Server Context
## with public directory
##
module.exports = 
    
    UID: 33 ## www-data

    ## basic implementation contains:
    ## static https-file server, ETag-caching, GZip compession, (TODO doc)
        
    type: 'http.HTTPSServer'

    data:
        port: 9443
        
    
