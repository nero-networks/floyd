
##
## A Simple Floyd-Webserver Example
##
## creates a simple Http-Server Context
## with public directory
##
module.exports =

    ## basic implementation contains:
    ## static file server, ETag-caching, GZip compession, (TODO doc)

    type: 'http.Server'

    data:
        port: 9035
        debug: true

    children: [

        ## mixing static files and dynamic routes
        ## this context serves /test/index.html and /test/boot.js

        type: 'http.Context'

        data:
            route: '/test'

        remote:

            children: [
                id: 'test'

                data:
                    logger:
                        level: 'STATUS'
            ]


    , # recognize the colon!


        ## simple logging context

        started: (fn)->

            @delegate '_addMiddleware', (req, res, next)=>

                req.on 'end', ()=>

                    ## write log on req.end
                    @logger.info 'hit on', req.url, res.statusCode


                next() ## continue request...

    ]
