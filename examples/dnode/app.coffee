
## try STATUS or DEBUG be carefull with FINE, FINER, FINEST
LOGLEVEL = 'INFO' 	

## disabeling the debug mode triggers uglify-ing /floyd.js... 
## this takes serveral seconds on the very first request after app restart
DEBUG = true		

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
                            $('.display').html '<p>'+txt+'ms</p>'
                                
