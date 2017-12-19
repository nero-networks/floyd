
module.exports =
    type: 'http.Server'

    children: [
        type: 'omarpc.HttpContext'

        registry:

            Test:
                ping: (i, fn)->
                    fn null, i
    ]
