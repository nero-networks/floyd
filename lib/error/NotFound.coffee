
message = "Das angeforderte Objekt '%s' konnte nicht gefunden werden."
# Sofern Sie die Adresse manuell eingegeben haben, überprüfen Sie bitte die Schreibweise und versuchen Sie es erneut.'

module.exports =

    ##
    ## @class floyd.error.NotFound
    ##
    class NotFound extends floyd.error.Exception

        name: 'floyd.error.NotFound'
        title: 'Objekt nicht gefunden'

        constructor: (uri)->
            super floyd.tools.strings.sprintf(message, uri), 404
