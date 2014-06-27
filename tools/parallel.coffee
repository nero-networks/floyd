##
## executes all threads and adds the result of the 
## callback to the results array in the same order.
## the result of threads[i] will be placed in results[i]
##
## examples
##
## 1. an arbitrary number of thread functions followed by
##    a callback function which recieves the results array
##    or an error object
##
##    floyd.tools.parallel (fn)->
##        fn null, 'res1'
##    , (fn)->
##        fn null, 'res2'
##    , (fn)->
##        fn null, 'res3'
##    , (fn)->
##        fn null, 'res4'
##    , (err, [r1, r2, r3, r4])->
##        console.log r1, r2, r3, r4
##    
##    >> res1 res2 res3 res4
##
## 2. an array with thread functions followed by a callback 
##    function which recieves the results array or an error object
##
##    threads = for i in [1..4]
##        do (i)->
##            (fn)-> fn null, 'res'+i
##    
##    floyd.tools.parallel threads, (err, [r1, r2, r3, r4])->
##        console.log r1, r2, r3, r4
##
##    >> res1 res2 res3 res4
##
module.exports = (threads..., done)->

    if typeof threads[0] isnt 'function'
        threads = threads[0]
    
    if !(count = threads.length)
        return done()
    
    error = null
    results = []
    
    for i in [0..threads.length-1]
        do (i)->
            setImmediate ->
            
                threads[i] (err, res)->
                    
                    if err
                        error = err 
                    
                    else
                        results[i] = res
                        
                    if --count is 0
                        done error, results
    
    return undefined
