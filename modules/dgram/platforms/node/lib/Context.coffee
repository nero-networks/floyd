
dgram = require 'dgram'

module.exports = 
    
    class DGramContext extends floyd.Context

        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config 
                
                data:
                    ports: []
                
            , config            
        
        
        ##
        ##
        ##
        boot: (done)->
            @_sockets = []
            
            @_process @data.ports,
                each: (conf, next)=>
                    @_sockets.push sock = dgram.createSocket 'udp4', (msg, info)=>
                        @_handleMessage sock, msg, info, conf
                    
                    sock.bind conf.port, conf.host, (err)=>
                        return next(err) if err
                        @logger.info 'listening for UDP on %s:%s', (conf.host||'0.0.0.0'), conf.port
                        
                        if conf.multicast
                            @_process conf.multicast,
                                each: (addr, fn)=>
                                    if typeof addr is 'string'
                                        addr =
                                            addr: addr
                                    
                                    sock.setBroadcast true
                                    sock.setMulticastTTL addr.ttl||128
                                    
                                    sock.addMembership addr.addr, addr.iface                                    
                                    
                                    @logger.info '    adding multicast membership: %s@%s', addr.addr, addr.iface||'all'
                                    
                                    fn()
                                    
                                done: next
                        
                        else next()
                
                done: done
        
        ##
        ##
        ##
        _handleMessage: (sock, msg, info, conf)->
            console.log 'incomming message:', msg, info, conf
        
                    