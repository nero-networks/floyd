
module.exports =
    type: 'http.Server'

    remote: ## running in the browser
        running: ->
            floyd.tools.omarpc.Proxy 'Test', (err, Test)=>
                button = document.querySelector 'button'

                counter = 0
                button.onclick = ()=>
                    start = +new Date()

                    Test.ping counter++, (err, i)=>
                        button.textContent = 'click me: '+(i + 1)+' - '+(+new Date() - start)+'ms'

    data:
        lib:
            modules: ['omarpc'] ## include this to have access to floyd.tools.omarpc.Proxy

    children: [
        type: 'omarpc.HttpContext'

        registry:

            ## this is the rpc api proxied in the browser
            Test:
                ping: (i, fn)->
                    fn null, i
    ]
