

module.exports =

    class UserData extends floyd.gui.ViewContext

        ##
        ##
        ##
        configure: (config)->
            super new floyd.Config

                data:
                    class: 'UserData'
                    admin: false
                    newUser: false
                    buttons:
                        submit: 'speichern'
                        close: 'schließen'

                    roles: ['admin']


                content: ->
                    h2 'Einstellungen | ', ->
                        span class: 'login'

                    p class:'hint'

                    form action:'#', method:'post', ->
                        if @data.admin
                            label 'Aktiviert'
                            input type: 'checkbox', name: 'active'

                            br()

                            if @data.newUser
                                label 'Username'
                                input type: 'text', name: 'login'

                                br()

                        label 'Passwort'
                        input type: 'password', name: 'pw1'
                        input type: 'password', name: 'pw2'

                        br()

                        label 'Name'
                        input type: 'text', name: 'name'

                        br()

                        label 'E-Mail'
                        input type: 'text', name: 'email'

                        br()

                        if @data.admin
                            label 'Rollen'

                            for role in @data.roles
                                span role
                                input type: 'checkbox', name: role

                            br()

                        div class:"buttons", ->
                            button class:'save', type:'submit', (@data.buttons.submit)

                            if @data.buttons.close
                                button class: 'close', (@data.buttons.close)

            , config


        ##
        ##
        ##
        wire: (done)->
            super (err)=>
                return done(err) if err

                hint = @find 'p.hint'

                ##
                _hasError = false
                error = (err)->
                    _hasError = true
                    hint.addClass('error').text err.message || err

                @_getBackend (err, ctx)=>
                    return error(err) if err

                    @_loadData ctx, (err, data)=>
                        return error(err) if err

                        @identity.hasRole 'admin', (err, isAdmin)=>
                            isAdmin = isAdmin && @data.admin

                            _login = @identity.login()

                            ## headline
                            @find('h2 .login').text (data.name||'')+' ('+(data.login||'neuer Benutzer')+')'

                            ## name
                            name = @find('[name=name]')
                            name.val(data.name) if data.name

                            ## email
                            email = @find('[name=email]')
                            email.val(data.email) if data.email

                            ## password
                            pw1 = @find('[name=pw1]')
                            pw2 = @find('[name=pw2]')

                            if isAdmin

                                ## active
                                active = @find('[name=active]')
                                if data.active isnt false || @data.newUser
                                    active.attr 'checked', true

                                if _login is data.login
                                    active.attr 'disabled', true

                                ## data
                                login = @find('[name=login]')

                                ## roles
                                if data.roles
                                    for role in @data.roles
                                        cbox = @find('[name='+role+']')
                                        if data.roles.indexOf(role) != -1
                                            cbox.attr 'checked', true

                                        if _login is data.login
                                            cbox.attr 'disabled', true


                            @find('form').on 'submit', ()=>
                                _hasError = false

                                hint.attr('class', 'hint').text ''

                                ## data
                                _save = ()=>

                                    ## name
                                    data.name = name.val()

                                    ## email
                                    if !(val = email.val()) || floyd.tools.strings.isEmail val
                                        data.email = val

                                    else
                                        error 'Es wurde eine ungültige E-Mail Adresse eingegeben'

                                    if isAdmin
                                        ## active
                                        data.active = !!active.attr('checked')

                                        ## roles
                                        data.roles = []
                                        for role in @data.roles
                                            if @find('[name='+role+']').attr('checked')
                                                data.roles.push role

                                    ## password
                                    _pw1 = pw1.val()
                                    _pw2 = pw2.val()

                                    if _pw1 && _pw1 is _pw2
                                        data.pass = floyd.tools.crypto.password.create _pw1

                                    else if _pw1 && _pw2
                                        error 'Die Passworte stimmen nicht überein'

                                    else if @data.newUser && !_pw1 && !_pw2
                                        error 'Es muss ein Passwort eingegeben werden'

                                    else if (_pw1 && !_pw2) || (!_pw1 && _pw2)
                                        error 'Das neue Passwort muss zweimal eingegeben werden'

                                    ##
                                    if !_hasError
                                        @_saveData ctx, data, (err)=>
                                            return error(err) if err

                                            hint.text 'Die Daten wurden erfolgreich gespeichert'

                                            pw1.val ''
                                            pw2.val ''


                                ##
                                if !@data.newUser || !isAdmin
                                    _save()

                                else

                                    ## login
                                    if !(val = login.val())
                                        error 'Es muss ein Username eingegeben werden'

                                    else
                                        ctx.load val, (err, _data)=>
                                            if !_data
                                                data.login = val

                                                _save()

                                            else
                                                error 'Der Username existiert bereits'


                                ##
                                return false

                ##
                done()


        ##
        ##
        ##
        _saveData: (ctx, data, fn)->
            ctx.save data, fn

        ##
        ##
        ##
        _loadData: (ctx, fn)->
            @identity.login (err, login)=>
                ctx.load login, fn
