
##
module.exports =

    ##
    ##
    ##
    class TingoStore extends floyd.stores.engines.MongoStore

        _connect: (o, fn)->
            root = process.getuid() is 0

            files = floyd.tools.files

            if !files.exists path = o.path||'.floyd/tingodb/'
                files.mkdir path
                root && files.chown path, floyd.system.UID, floyd.system.GID

            if !files.exists dbpath = files.path.join path, o.name
                files.mkdir dbpath
                root && files.chown dbpath, floyd.system.UID, floyd.system.GID

            if !files.exists dbfile = files.path.join dbpath, o.collection
                files.write dbfile, ''
                root && files.chown dbfile, floyd.system.UID, floyd.system.GID

            ##
            Db = require('tingodb')().Db
            fn null, new Db path+o.name, {}
