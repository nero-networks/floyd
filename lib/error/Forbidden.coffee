
message = "Der Zugriff auf das angeforderte Objekt '%s' ist nicht erlaubt."
# Entweder kann es vom Server nicht gelesen werden oder es ist zugriffsgeschützt.'

module.exports =

    ##
    ## @class floyd.error.Forbidden
    ##
    class Forbidden extends floyd.error.Exception

        name: 'floyd.error.Forbidden'
        title: 'Zugriff verweigert!'

        constructor: (uri)->
            super floyd.tools.strings.sprintf(message, uri), 403
