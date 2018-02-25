swagger = require 'swagger-tools'
yaml = require 'js-yaml'

module.exports =

    class SwaggerContext extends floyd.Context

        ##
        configure: (config)->
            @_System = config.System || {}

            super new floyd.Config
                data:
                    file: './swagger.yaml'
                    ui: '/api-docs'
                    authManager: 'sessions'
                    usersStore: 'users'

            , config

        ##
        ##
        ##
        start: (done)->
            super (err)=>
                return done(err) if err

                omarpc = new floyd.omarpc.OMAExecutor @

                docs = yaml.safeLoad floyd.tools.files.read @data.file

                swagger.initializeMiddleware docs, (m)=>
                    @_addMiddleware m.swaggerMetadata()
                    @_addMiddleware m.swaggerValidator()

                    @_addMiddleware (req, res, next)=>
                        if req.swagger?.operation
                            o = req.swagger.operation.tags[0]
                            m = req.swagger.operation.operationId
                            @_prepareArgs req, (err, a)=>
                                return fn(err) if err

                                try
                                    @_getAuthKey req, (err, SID)=>
                                        return fn(err) if err

                                        @logger.debug 'executing for %s - %s.%s(%s)', SID, o, m, a

                                        omarpc.execute SID, o, m, a, (err, result)=>
                                            return @_sendError(req, res, err) if err
                                            @_sendResult req, res, result
                                catch err
                                    @_sendError req, res, err

                        else next()

                    @_addMiddleware m.swaggerUi
                        swaggerUi: @data.ui

                    @logger.info 'swagger running...'

                done()

        ##
        ##
        ##
        _addMiddleware: (mw)->
            @delegate '_addMiddleware', mw


        ##
        ##
        ##
        _getAuthKey: (req, fn)->
            find = (auth)->

            for auth in req.swagger.security
                for key, roles of auth
                    def = req.swagger.swaggerObject.securityDefinitions[key]

                    if def.in is 'header'
                        SID = req.headers[def.name.toLowerCase()]

                    ## TODO implement oAuth + cookie

                    return fn(null, SID) if SID

            ## still here?
            fn()


        ##
        ##
        ##
        _prepareArgs: (req, fn)->
            args = []
            if req.swagger.operation.parameters?.length
                for param in req.swagger.operation.parameters
                    args.push req.swagger.params[param.name]?.value
            fn null, args


        ##
        ##
        ##
        _sendResult: (req, res, result)->
            res.ctype = req.swagger.operation.produces?[0] || 'application/json'
            res.send JSON.stringify(result), 200


        ##
        ##
        ##
        _sendError: (req, res, err)->
            code = err.status || 500
            msg = req.swagger.operation.responses[code]?.description || err.message || 'Internal Server Error'

            @logger.error err

            res.ctype = 'text/plain'
            res.send msg, code

        ##
        ##
        ##
        _executeSystem: (SID, ident, o, m, a, fn)->
            if @_System[m]
                @_System[m].apply @, a.concat ident, fn
                return true
            return false
