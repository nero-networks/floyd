
module.exports =

    ##
    sendMail: (data, fn)->

        for field in ['subject', 'from', 'to', 'text']

            if !data[field]
                return fn new Error 'verify '+field

        if !floyd.tools.strings.isEmail data.from
            return fn new Error 'verify from'

        if !floyd.tools.strings.isEmail data.to
            return fn new Error 'verify to'

        mailer = require('nodemailer').createTransport 
            sendmail: true

        mailer.sendMail data, fn

    ##
    format: (txt, wrap=70)->
        words = txt.split ' '
        txt = ''

        lines = 1
        while words.length
            word = words.shift()
            if txt.length + word.length > wrap * lines
                lines++
                txt += word + '\n'
            else
                txt += word + ' '

        return txt.trimRight()
