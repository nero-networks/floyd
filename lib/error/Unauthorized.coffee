
message = "Der Zugriff auf den Bereich '%s' wurde nicht autorisiert."

#Sofern Sie für den Zugriff berechtigt sind, überprüfen Sie bitte die eingegebenen Zugangsdaten und versuchen Sie es erneut.'

module.exports =

    ##
    ## @class floyd.error.Unauthorized
    ##
    class Unauthorized extends floyd.error.Exception

        name: 'floyd.error.Unauthorized'
        title: 'Autorisierung erforderlich'

        constructor: (@realm)->
            super floyd.tools.strings.sprintf(message, @realm), 401
