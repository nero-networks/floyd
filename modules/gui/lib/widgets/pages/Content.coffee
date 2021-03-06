
module.exports =

    class ContentContext extends floyd.gui.ViewContext

        configure: (config)->

            super new floyd.Config

                data:
                    adminnavi:
                        parent: '#header'

            , config



        ##
        ##
        wire: (done)->
            super (err)=>
                done(err)

                #console.log @identity.login(), floyd.system.platform, location.pathname

                if @identity.login()

                    path = location.pathname.substr(1).split('/')
                    path.pop()

                    origin = @data.find 'origin'

                    @lookup origin, @identity, (err, ctx)=>
                        return done(err) if err

                        $(@data.adminnavi.parent).append ul = $('<ul class="adminnavi"/>')
                        _mklink = (roles, id, handler)=>
                            return if roles.length > 0 && !@identity.hasRole roles

                            ul.append $('<li><a href="#" class="'+id+'">'+(@data.adminnavi[id]||id)+'</a></li>').click (e)=>
                                handler(e)
                                return false

                        @_makeAdminNavi ctx, _mklink, done

        ##
        ##
        ##
        _makeAdminNavi: (ctx, _mklink, done)->
            _mklink ['editor'], 'edit', ()=> @_openEditor 'File', ctx
            _mklink [], 'logout', ()=> @_getAuthManager().logout (err)=> location.reload()

            done()

        ##
        ##
        ##
        _openEditor: (type, ctx)->

            ##
            ctx['read'+type] (err, data)=>

                return @logger.error(err) if err

                ##
                floyd.tools.gui.popup @,

                    id: 'editor'

                    data:
                       close: false

                    buttons:
                        content: ->
                            button class: 'cancel', 'Abbrechen'
                            button class: 'save', 'Speichern'

                , (err, popup)=>

                    popup.append textarea = $('<textarea/>').val(data)

                    popup.on 'cancel', -> location.reload()

                    popup.on 'save', (e)=>

                        ctx['write'+type] textarea.val(), (err)=>

                            if err
                                alert(err.message)

                            else location.reload()
