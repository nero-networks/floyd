
spawn = require('child_process').spawn

module.exports =

    ##
    ##
    ##
    class Director extends floyd.Context


        ##
        ##
        ##
        configure: (config)->

            @_processes = {}

            config.data ?= {}
            config.data.workers_dir ?= 'workers'

            if !floyd.tools.files.exists config.data.workers_dir
                floyd.tools.files.mkdir config.data.workers_dir
                if floyd.system.UID == 0 && config UID
                    floyd.tools.files.chown config.data.workers_dir, config.UID, (config.GID || config.UID)
                floyd.tools.files.chmod config.data.workers_dir, '2755'

            if !(socket = config.data?.socket)
                socket = floyd.tools.files.tmp 'dnode.cluster.Director-'+config.id, 'sock'

            if floyd.tools.files.exists socket
                floyd.tools.files.rm socket


            #floyd.system.GID = floyd.system.UID = 0

            super new floyd.Config

                data:
                    socket: socket

                children: [

                    id: 'bridge'

                    type: 'dnode.Bridge'

                    data:
                        ports: [path: socket]

                ]

            , config



        ##
        ##
        ##
        _createChild: (child, done)->
            if !child.isClusterWorker
                super child, done

            else
                child.id ?= @__ctxID()

                child.ID = @ID+'.'+child.id

                ##
                child = new floyd.Config
                    _spawned: 0

                    children: [
                        type: 'repl.Context'
                    ,
                        id: 'bridge'
                        type: 'dnode.Bridge'

                        data:
                            gateways: [
                                path: @data.socket
                                keepalive: false
                            ]

                            logger:
                                level: @data.find 'logger.level'
                    ]
                    system:
                        appdir: floyd.system.appdir+'/'+@data.workers_dir+'/'+child.id
                        tempdir: floyd.system.appdir+'/'+@data.workers_dir+'/'+child.id+'/.floyd/tmp'

                    ORIGIN: @ID

                    booted: -> @logger.debug 'starting child process'

                , child

                ## prepare working directory
                files = floyd.tools.files
                ##
                if !files.exists child.system.appdir
                    files.mkdir child.system.appdir


                if !files.exists child.system.tempdir
                    files.mkdir child.system.tempdir


                ##
                name = child.system.appdir+'/.app.js'
                model = floyd.tools.objects.serialize child, 4

                files.write name, '// generated file... do not edit!' + new Date() + '\nrequire("floyd").init('+model+')'

                ##
                @logger.debug 'spawning child %s.%s', @ID, child.id
                @_spawnChild child, done


        ##
        ##
        ##
        _spawnChild: (child, done)->
            child._spawned++

            ##
            proc = @_processes[child.id] = spawn process.execPath, [child.system.appdir+'/.app'],
                cwd: child.system.appdir

            proc.stdout.pipe process.stdout

            proc.stderr.pipe process.stderr

            proc.on 'close', ()=>
                if @_status.indexOf('shutdown') is -1
                    if child._spawned < 100
                        @logger.warning 're-spawning child %s.%s (%s)', @ID, child.id, child._spawned
                        @_spawnChild child
                    else
                        @logger.warning 'respawning FAILED for %s.%s (%s)', @ID, child.id, child._spawned

            ##
            done?()



        ##
        ##
        ##
        stop: (done)->
            super (err)=>
                return done(err) if err

                @_process @_processes,
                    each: (id, child, next)=>
                        child.on 'close', next
                        child.kill()

                    done: done
