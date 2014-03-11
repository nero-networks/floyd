
module.exports = tools = 
    
    ##
    ##
    ##
    page: (route, config)->
        
        new floyd.Config
            type: 'gui.HttpContext'
            
            data:
                route: route
                
                file: 'index.html'
            
            remote: 
                  
                children: [
                    
                    new floyd.Config
                        type: 'gui.ViewContext' 
                            
                        data:
                            selector: 'body'
                    
                    , config.content
                        
                ]
                
        , config
    
    
    ##
    ##
    ##
    dnodePage: (route, config)->
    
        tools.page route, new floyd.Config
            
            local:
                type: 'Context'
            
            remote:
                type: 'dnode.Bridge'
        
        , config
        