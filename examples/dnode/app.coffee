
LOGLEVEL = 'INFO' 	## try STATUS or DEBUG be carefull with FINE, FINER, FINEST

DEBUG = true		## disabeling the debug mode triggers uglify-ing /floyd.js... 
                    ## this takes serveral seconds on the very first reguest after app restart

##
## dnode example...
##
module.exports = 
    
    new floyd.Config 'config.gui.server',  'config.dnode.server', 
    
        data:
            port: 9032
            
            debug: DEBUG
            
            logger: (level:LOGLEVEL)
        
        children : [
        
            id: 'test'
            
            children: [
            
                id: 'echo'
            
                echo: (input, fn)->
                    fn null, input+' <-> '+@ID
                                
            ]
            
        ]			
            
        ##
        remote:
        
            type: 'dnode.Bridge'
            
            data:
                debug: DEBUG
                
                logger: (level:LOGLEVEL)
            
            booted: ()->
            
                @lookup 'test.echo', @identity, (err, ctx)=>				
                    return console.error(err) if err

                    $('button').click ()=>	
                        start = +new Date()
                    
                        ctx.echo @ID, (err, res)=>
                            txt = res + ' roundtrip: ' + (+new Date() - start)
                            console.log txt
                            $('body').append '<p>'+txt+'ms</p>'
                                
