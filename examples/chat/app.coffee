
##
## pubsub chat
##

module.exports = 

    new floyd.Config 'config.gui.server', 'config.dnode.server', 
        
        ##		
        data:
            port: 9038
            debug: true


        ##	
        children: [
        
            id: 'pubsub'
            
            type: 'data.PubSubContext'
                        
        ]
        
        ##	
        remote:
            
            type: 'dnode.Bridge'
            
            children: [
                
                type: 'PubSubChat'
                
                data:
                    selector: 'body'
                    
            ]

    
