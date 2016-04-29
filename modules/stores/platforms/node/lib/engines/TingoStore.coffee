
##
module.exports =

    ##
    ##
    ##
    class TingoStore extends floyd.stores.engines.MongoStore

        _connect: (o, fn)->
            path = o.path||'.floyd/tingodb/'
            floyd.tools.files.mkdir path+o.name

            Db = require('tingodb')().Db
            fn null, new Db path+o.name, {}
