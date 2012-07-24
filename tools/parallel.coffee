
##
## 
##

module.exports = (threads..., done)->

    if !(count = threads.length)
        return done()

    floyd.tools.objects.process threads,
        
        each: (worker, next)->
            process.nextTick ->
            
                worker (err)->
                    done(err) if err
                    
                    if --count is 0
                        done() 
    
            next()
            