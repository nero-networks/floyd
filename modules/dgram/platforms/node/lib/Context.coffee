
dgram = require 'dgram'

module.exports = 
    
    class DGramContext extends floyd.Context

        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config 
                
                data:
                    port: null
                
            , config            
        
        
        ##
        ##
        ##
        boot: (done)->
            if @data.port
                dgram.createSocket 'udp4', (msg, info)=>
                    @_handleMessage msg, info
                    
                .bind @data.port, @data.host
                
                done()
        
        ##
        ##
        ##
        _handleMessage: (msg, info)->
            console.log 'incomming message:', msg, info
        
        
        ##
        ##
        ##
        _sendMessage: (msg, port, host, fn)->
            if typeof host is 'function'
                fn = host
                host = '127.0.0.1'            
        
            buff = new Buffer msg
            
            dgram.createSocket('udp4').send buff, 0, buff.length, port, host, fn
            
            