##
##
##
module.exports =

    UID: 0
    GID: 0
    type: 'dnode.cluster.Director'

    #data:
    #    logger:
    #        level: 'STATUS'

    children: [

        UID: 65534
        GID: 65534

        id: 'frontend'

        isClusterWorker: true

        children: [

            new floyd.Config 'config.dnode.server', 'config.gui.server',

                id: 'server'

                data:
                    debug: true

                    #logger:
                    #    level: 'DEBUG'

                    rewrite:
                        '^/((index.html)|(boot.js))?$': '/home/$1'

                children: [

                    id: 'users'
                    data:
                        type: 'object'

                    memory:
                        test:
                            roles: ["tester"]
                            ## try 'asdf'
                            pass: '8e19a8e1ab8ee4ec4686a558b0bb221d-SHA256-4-1500-999126a0c5af65781f9b72f4e538d2d8'

                ,

                    type: 'gui.HttpContext'

                    data:
                        route: '/home/'

                        file: '/index.html'

                    remote:

                        type: 'dnode.Bridge'

                        data:
                            debug: true

                        children: [

                            type: 'gui.widgets.LoginBox'

                            building: (done)->
                                @_test done

                            wiring: ()->
                                @on 'login', ()=>
                                    @_test()

                                $('#update').click ()=>
                                    @_test()

                            _test: (done)->
                                @lookup 'backend.data', @identity, (err, backend)=>
                                    return done(err) if err

                                    backend.test (err, data)=>

                                        $('#date').text err?.message || data

                                        done?()

                        ]
                ]

        ]

    ,

        UID: 33
        GID: 33

        id: 'backend'

        isClusterWorker: true

        children: [

            id: 'data'

            permissions:
                test:
                    roles: 'tester'

            test: (fn)->
                fn null, new Date()

        ]

    ]
