
module.exports =

    ##
    ##
    ##
    class Router

        ##
        ##
        ##
        constructor: (@ID)->

            @_routes = []


        ##
        ##
        ##
        add: (route, handler)->

            @_routes.push new @Route route, handler, @


        ##
        ##
        ##
        handle: (req, res, next)->

            uri = req.uri

            routes = []

            for route in @_routes

                if route.match req, res
                    routes.push route


            _next = ()=>
                return next() if !routes.length

                #console.log 'trying', @ID, routes[0].route, req.url

                routes.shift().handle req, res, (err)=>
                    return next(err) if err

                    _next()

            _next()


        ##
        ##
        ##
        Route:

            ##
            ##
            ##
            class Route

                ##
                ##
                constructor: (@route, @handler, @router)->
                    #console.log '   new Route', @route, @router.ID


                ##
                ##
                match: (req)->

                    uri = req.uri.split('?').shift()

                    if typeof @route is 'function'
                        @route req, uri

                    else
                        uri.match @route


                ##
                ##
                handle: (req, res, next)->

                    req.params = @match req

                    @handler req, res, next
