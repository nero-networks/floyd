
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
            @_socket = dgram.createSocket 'udp4', (msg, info)=>
                @_handleMessage msg, info

            @_socket.bind @data.port, @data.host, (err)=>
                return done(err) if err

                @logger.info 'listening for UDP on %s:%s', (@data.host||'0.0.0.0'), @data.port

                if multicast = @data.multicast
                    if typeof multicast is 'string'
                        multicast =
                            address: multicast

                    @_socket.setBroadcast true
                    @_socket.setMulticastTTL multicast.ttl||128

                    @_socket.addMembership multicast.address, multicast.iface

                    @logger.info '    adding multicast membership: %s@%s', multicast.address, multicast.iface||'all'

                    done()

        ##
        ##
        ##
        _handleMessage: (msg, info)->



        ##
        ##
        ##
        _sendMessage: (msg, host, port, fn)->
            if typeof host is 'function'
                fn = host
                host = '127.0.0.1'

            if typeof msg isnt 'string' && !(msg instanceof Buffer)
                msg = JSON.stringify msg

            if !(msg instanceof Buffer)
                msg = Buffer.from msg
            
            @_socket.send msg, 0, msg.length, port, host, fn
