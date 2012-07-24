
message = "Die aufgerufene Funktion '%s' ist nicht Implementiert!"

module.exports =

    ##
    ## @class floyd.error.NotImplemented
    ##
    class NotImplemented extends floyd.error.Exception

        name: 'floyd.error.NotImplemented'
        title: 'Unimplementierte Funktion'

        constructor: (method)->
            super floyd.tools.strings.sprintf(message, method), 501
            
            
            