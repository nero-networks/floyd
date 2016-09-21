
module.exports =

    class TestContext extends floyd.Context
        ##
        runTests: (done)->
            _cnt = 0
            _err = 0
            fn = (name, err, next)=>
                _cnt++
                if err
                    _err++
                    @logger.warning floyd.tools.strings.sprintf '%-15s - Failed: %s', name, err.message
                else @logger.debug floyd.tools.strings.sprintf '%-15s - OK', name
                next?()

            @prepareTests ()=>
                @_process @,
                    each: (name, method, next)=>
                        if typeof method is 'function' && name.match /^test/
                            method.apply @, [(err)=> fn name, err, next]
                        else next()

                    done: ()=>
                        @_process @children,
                            each: (child, next)=>
                                child.runTests ?= @runTests
                                child.runTests next
                            done: ()=>
                                if _cnt
                                    @logger.info 'finished %s test with %d errors', _cnt, _err

                                @cleanupTests done

        ##
        ##
        ##
        prepareTests: (done)->
            @_process @children,
                each: (child, next)=>
                    if child.prepareTests
                        child.prepareTests next
                    else next()
                done: done

        ##
        ##
        ##
        cleanupTests: (done)->
            @_process @children,
                each: (child, next)=>
                    child.cleanupTests? next
                done: done
