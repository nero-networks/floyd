
module.exports =

    ##
    ## A Floyd HTTPS enabled Webserver 
    ##
    ## Implements a nodeish _createServer method for the Floyd HTTPS-Server Context
    ##
    ## @platform node
    class NodeHttpsServer extends floyd.http.Server
        
        ##
        ##
        ## @override
        configure: (config)->
            super new floyd.Config
            
                data:
                    module: 'https'
                    port: 443
        
                    cert: './private/https.cert'
                    key: './private/https.key'
            , config
                    
        
        ##
        ##
        ##
        _createServer: (handler)->
            
            options =
                cert: floyd.tools.files.read @data.cert
                key: floyd.tools.files.read @data.key
                
            @_module.createServer options, handler
            
            
            