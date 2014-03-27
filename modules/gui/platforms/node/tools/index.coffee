
module.exports = tools = 
    
    ##
    ##
    ##
    page: (route, config)->
        if typeof config.content is 'object'
            console.warn config.id, 'config.content creates conflicts! use config.gui instead'
            config.gui = floyd.tools.objects.cut config, 'content'
            
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
                    
                    , config.gui
                        
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
        