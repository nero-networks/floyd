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
                pass: 'd6b09dd822468d9dcc3fbe6f1497bf83-SHA256-4-1000-360c87fe1ee6cc80c1afcded5079056e'

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
