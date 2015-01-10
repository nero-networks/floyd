
module.exports =
    
    class UserList extends floyd.gui.widgets.List
        
        ##
        configure: (config)->            
            super new floyd.Config
                
                data:
                    class: 'UserList'
                    listSelector: 'tbody'
                                   
                content: ->
                    h2 'Benutzer'
                    
                    table ->
                        thead ->
                            tr ->
                                th class: 'login', 'Benutzername'
                                th class: 'name', 'Name'
                                th class: 'email', 'E-Mail'
                                th class: 'roles', 'Rollen'
                                th class: 'lastlogin', 'letzter Login'
                        tbody()

                
                widget: ->
                    _attr = 
                        'data-login': @login
                        
                    _attr.class = @__class if @__class
                    if @active is false
                        if !_attr.class
                            _attr.class = 'inactive'
                        else
                            _attr.class += ' inactive'
                    
                    tr _attr, ->
                        td class: 'login', @login
                        
                        td class: 'name', @name
                        td class: 'email', @email
                        
                        td class: 'roles', (@roles?.join?(', ')||@roles)
                        
                        td class: 'lastlogin', ->
                            if typeof @lastlogin is 'string'
                                @lastlogin
                            else if @lastlogin
                                floyd.tools.date.format new Date(@lastlogin), 'DD.MM.YYYY HH:mm:SS'
                
                _loadData: (offset, limit, fn)->

                    @_getBackend (err, ctx)=>
                        return fn(err) if err
                        
                        ctx.list offset, limit, fn
                        
            
                children: [
                    new floyd.Config
                        type: 'gui.editor.ListEditor'
                    
                        data:
                            itemSelector: 'tbody > tr > td'
                    
                        each:
                            buttons:
                                edit: 
                                    text: 'bearbeiten'
                                
                                del: 
                                    text: 'löschen'
                        
                            _show: (event)->
                                @__root.css top: $(event.currentTarget).position().top
                                if @identity.login() is $(event.currentTarget).parent().data('login')
                                    @find('.del').hide()
                                else
                                    @find('.del').show()
                                
                                @__root.show()
                    
                        add: 
                            text: 'Neuer Benutzer'
                    
                        events:
                            add: (e)->
                                _popup = null
                                _saved = ()=>
                                    @_emit 'saved'
                                    setTimeout ()=>
                                        _popup.close()
                                    , 500
                                
                                _cfg = new floyd.Config 
                                    class: 'narrow'
                            
                                    type: 'gui.widgets.users.UserData'
                            
                                    data:
                                        newUser: true
                                        admin: true
                                        buttons:
                                            submit: 'anlegen'
                                    
                                    _loadData: (ctx, fn)->
                                        fn null, {}
                            
                                    _saveData: (ctx, data, fn)->
                                        @_saveData._super ctx, data, (err)=>
                                            return fn(err) if err
                                            _saved()
                                            fn()

                                , @data.find('widgets.userdata')
                                
                                e.open _cfg, (err, popup)=>
                                    _popup = popup
                                       
                            edit: (e)->
                                _popup = null
                                _saved = ()=>
                                    @_emit 'saved'
                                    setTimeout ()=>
                                        _popup.close()
                                    , 500
                                
                                _cfg = new floyd.Config
                                    class: 'narrow'

                                    type: 'gui.widgets.users.UserData'
                            
                                    data:
                                        admin: true
                                    
                                    _loadData: (ctx, fn)->
                                        ctx.load e.parent.parent().data('login'), fn
                        
                                    _saveData: (ctx, data, fn)->
                                        @_saveData._super ctx, data, (err)=>
                                            return fn(err) if err
                                            _saved()
                                            fn()
                                        
                                , @data.find('widgets.userdata')
                                    
                                e.open _cfg, (err, popup)=>
                                    _popup = popup
                    
                            del: (e)->
                                user = e.parent.parent().data('login')
                            
                                if confirm user+' wirklich löschen'
                                    @_getBackend (err, ctx)=>
                                        return @error(err) if err
                                    
                                        ctx.del user, (err)=>
                                            return alert(err.message) if err
                                        
                                            @_emit 'saved'
                                        
                            saved: ()->
                                @parent._reload()
                    
                    , config.editor
                
                ]
                
            , config
        
        