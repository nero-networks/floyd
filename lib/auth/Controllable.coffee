
module.exports =

    ##
    ## @class floyd.auth.Controllable
    ##
    class Controllable

        ##
        ##
        ##
        constructor: (@ID, @parent)->

            @_hiddenKeys = ['constructor', 'identity', 'parent', 'logger', 'destroy']

            if @ID
                @logger = @_createLogger @ID

                @identity = @_createIdentity()


        ##
        ##
        ##
        destroy: (done)->
            @logger.finer 'destroy', @identity.id, done
            @_getAuthManager().destroyIdentity @identity, (err)=>
                return done(err) if err

                if @__authManager
                    @_getAuthManager().destroy done

                else done()
        ##
        ##
        ##
        _createLogger: (id)->

            new floyd.logger.Logger id


        ##
        ##
        ##
        _createIdentity: (id)->
            if @identity
                id = @identity.id+'.'+id
            else
                id = @ID

            @logger.finer 'createIdentity', id
            @_getAuthManager().createIdentity id



        ##
        ##
        ##
        _getAuthManager: ()->
            if ( manager = @__authManager || @parent?._getAuthManager?() )
                return manager

            @__authManager = @_createAuthManager()



        ##
        ##
        ##
        _createAuthManager: ()->
            new floyd.auth.Manager @_createAuthHandler()


        ##
        ##
        ##
        _createAuthHandler: ()->
            new floyd.auth.Handler()

        ##
        ## @param identity -
        ##
        forIdentity: (identity, fn)->

            @logger.finer 'forIdentity', identity.id

            @_allowAccess identity, (err)=>
                if err
                    @logger.warning 'access denied to', identity.id
                    return fn(err)

                @logger.fine 'access granted to', identity.id

                wrapper = {}

                ##
                floyd.tools.objects.process @,

                    ##
                    each: (key, value, next)=>
                        if key.charAt(0) isnt '_' && @_hiddenKeys.indexOf(key) is -1

                            if typeof value is 'function'

                                wrapper[key] = (_args...)=>

                                    @_permitAccess identity, key, _args, (err)=>
                                        if err
                                            @logger.warning 'access to % denied to %s', key, identity.id
                                            if typeof (_fn = _args.pop()) is 'function'
                                                return _fn err
                                            else
                                                throw err

                                        ## EXPERIMENTAL bind the identity to the method...
                                        value.identity = identity

                                        try
                                            res = value.apply @, _args
                                            value.identity = @identity

                                        catch err
                                            value.identity = @identity

                                            if typeof (_fn = _args.pop()) is 'function'
                                                return _fn err
                                            else
                                                throw err


                                        return res

                            else

                                wrapper[key] = value


                        next()


                    ##
                    done: (err)->
                        return fn(err) if err
                        process.nextTick ()-> ## this is to prevent loooong stack traces
                            fn null, wrapper



        ##
        ##
        ##
        _allowAccess: (identity, fn)->
            @logger.finest '_allowAccess', identity.id
            @_getAuthManager().authenticate identity, fn




        ##
        ##
        ##
        _permitAccess: (identity, key, args, fn)->

            fn null, key.charAt(0) isnt '_' && @_hiddenKeys.indexOf(key) is -1
