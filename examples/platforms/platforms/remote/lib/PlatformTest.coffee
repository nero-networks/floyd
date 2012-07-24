
module.exports =

    class RemotePlatformTest extends floyd.Context
    
        start: (fn)->
            super fn

            @logger.info 'Platform: %s', navigator.userAgent
            