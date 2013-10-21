
mailer = require('nodemailer').createTransport 'SMTP'

module.exports =
    
    class ContactPage extends floyd.gui.pages.PageContext
    
        ##
        ##
        ##
        configure: (config)->

            super new floyd.Config
                
                data:
                    rcpt: 'root@localhost'
                    
                    strings:

                        subject: 'Kontaktanfrage - '

                        systemerror: 'error sending system mail'
                        systemtext: '''Hallo,

am %(date)s um %(time)sh wurde über das Kontaktformular
folgende Nachricht an Sie gesendet:

Absender: %(name)s (%(email)s)

Betreff: %(subject)s
 
%(message)s


Viele Grüße und einen schönen Tag wünscht

Ihr Webserver'''



                        usererror: 'error sending user mail'
                        usertext: '''Hallo %(name)s,
                    
Sie haben am %(date)s um %(time)sh über unser Kontaktformular
folgende Nachricht an uns gesendet:

Betreff: %(subject)s
 
%(message)s


Viele Grüsse und einen schönen Tag

-----------------------------------------------------------------------
Diese E-Mail wurde, zur Bestätigung, automatisch versendet.'''

                    
                
            , config
        
        
        ##
        ##
        ##
        start: (done)->            
            super done 
            
            @_addRoute '/sendMail', (req, res, next)=>
                    
                @logger.warning 'post handler usage for ContactForm'
                
                floyd.tools.http.parseData req, (err, data)=>
                    return next(err) if err
                
                    @sendMail data, (err, verify)=>
                        if !err && verify?.length
                            err = new Error 'verify data-fields:'+verify.join(',')
                        
                        if err
                            next err
                        
                        else
                            res.redirect req.headers.referer+'?ok'
                        
                        
                        
            
                
        ##
        ##
        ##
        sendMail: (data, fn)->
            
            verify = []
            
            if !floyd.tools.strings.isEmail data.email
                verify.push 'email'
            
            for key, val of data
                verify.push(key) if !val && verify.indexOf(key) is -1
            
            if verify.length
                
                fn null, verify
                
            else
            
                date = floyd.tools.date.format(new Date(), 'DD.MM.YYYY HH:mm').split(' ')
                
                data.date = date[0]
                data.time = date[1]
    
                mailbody =
                    subject: @data.strings.subject + floyd.tools.strings.shorten data.subject, 15
                    from: data.email
                    to: @data.find('rcpt', 'root')
                    text: floyd.tools.strings.sprintf @data.strings.systemtext, data
                
                ## send system mail
                mailer.sendMail mailbody, (err, ok)=>
                    
                    return fn(err) if err
                    
                    if !ok                    
                        fn new floyd.error.Exception @data.strings.systemerror
                    
                    else
                        data.message = floyd.tools.strings.shorten data.message, 42
                        
                        mailbody.sender = mailbody.to
                        mailbody.to = data.email
                        mailbody.body = floyd.tools.strings.sprintf @data.strings.usertext, data
                        
                        ## send user mail
                        mailer.sendMail mailbody, (err, ok)=>
                            
                            #console.log 'usermail', err, ok
                    
                            if !ok && !err
                                err = new floyd.error.Exception @data.strings.usererror
                            
                            ## success if !err
                            fn err        

            
            