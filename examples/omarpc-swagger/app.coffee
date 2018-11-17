##
## Swagger RpcServer Example
##
## http://localhost:9088/api/echo?in=hallo
## http://localhost:9088/api-docs/
## user: test, pass: asdf
##
module.exports =

    type: 'http.Server'

    data:
        port: 9088

        #logger:
        #    level: 'DEBUG'

        sessions:
            cookie: false # deactivates cookie SID middleware


    children: [

        ## substitute the users db with data
        id: 'users'

        memory:
            test:
                roles: ["tester"]
                pass: '8e19a8e1ab8ee4ec4686a558b0bb221d-SHA256-4-1500-999126a0c5af65781f9b72f4e538d2d8'

    ,

        ## setup a RpcServer context
        type: 'omarpc.SwaggerContext'

    ,

        ## setup a simple Context with a protected method
        id: 'test'

        permissions:
            secret:
                roles: 'tester'

        ## this method is public for everyone
        echo: (str, fn)->
            fn null, str

        ## only users with the tester role can access this method
        secret: (fn)->
            fn null, 'Secret: 42'

    ]
