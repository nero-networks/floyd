
dgram = require 'dgram'

SOCKET = dgram.createSocket('udp4')

module.exports = 
    
    dgram: dgram
    
    send: (msg, port, host, fn)->
        if typeof host is 'function'
            fn = host
            host = '127.0.0.1'            
            
        if typeof msg isnt 'string'
            msg = JSON.stringify msg
    
        buff = new Buffer msg
        
        SOCKET.send buff, 0, buff.length, port, host, fn
            
            