
module.exports = 
    
    data:
        logger:
            level: 'STATUS'
    
    started: ()->
        @logger.info 'Hello World!'

