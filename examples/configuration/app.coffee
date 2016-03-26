
module.exports =

    new floyd.Config 'config.fromfile',

        data:
            extended: true

    , ->

        @data.functional = true

    ,

        configured: ()->
            console.log @data
