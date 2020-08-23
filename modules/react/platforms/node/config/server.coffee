

module.exports =

    type: 'http.Server'

    data:
        port: 9087
        lib:
            modules: ['react']
            node_modules: ['react', 'react-dom']
            files: ['./components/**']


    remote:
        type: 'react.Context'
