
mailer = require('nodemailer').createTransport 'SMTP'

module.exports = 

    sendMail: (data, fn)->
        
        for field in ['subject', 'from', 'to', 'text']
            
            if !data[field]
                return fn new Error 'verify '+field
            
        if !floyd.tools.strings.isEmail data.from
            return fn new Error 'verify from'
        
        if !floyd.tools.strings.isEmail data.to
            return fn new Error 'verify to'
        
        mailer.sendMail data, fn
        