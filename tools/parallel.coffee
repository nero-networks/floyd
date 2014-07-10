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
    
    if !(threads instanceof floyd.tools.parallel.Stack)
        threads = new floyd.tools.parallel.Stack threads
    
    threads.run done
    

module.exports.Stack = 
    
    class Stack extends Array
        
        ##
        constructor: (threads)->
            super()
            @_count = 0
            
            if threads
                for thread in threads
                    @push thread
        
            @_error = null
            @_results = []
        
        
        ##
        ##
        run: (@_done)->        
            if !@_count
                return @_done()
            
            @_running = true
            
            for i in [0..@length-1]
                @_exec i
        
            return undefined
        
        
        ##
        ##
        push: (thread)->
            super thread
            @_count++

            if @_running            
                @_exec @length - 1
            
        
        
        ##    
        _exec: (i)->
            setImmediate =>
    
                @[i] (err, res)=>
            
                    if err
                        @_error = err 
            
                    else
                        @_results[i] = res
                
                    if --@_count is 0
                        @_running = false
                        @_done @_error, @_results
        
        
    