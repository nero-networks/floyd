
module.exports = 

    class UserWidget extends floyd.gui.editor.Editor
    
        ##
        configure: (config)->            
            super new floyd.Config
            
                data:
                    class: 'UserWidget'
                    backend: 'userbackend'
                    
                    widgets:
                        userdata: 
                            class: 'narrow'
                            type: 'gui.widgets.users.UserData'
                            
                        userlist: 
                            type: 'gui.widgets.users.UserList'
                
                buttons:
                    userdata: 
                        text: 'Benutzerdaten'
                        
                    userlist: 
                        text: 'Alle Benutzer'
                        roles: ['admin']
                
                events:
                    userdata: (e)->
                        _popup = null
                        _saved = ()=>
                            @_emit 'saved'
                            setTimeout ()=>
                                _popup.close()
                            , 500

                        e.open new floyd.Config @data.widgets.userdata,
                            _saveData: (ctx, data, fn)->
                                @_saveData._super ctx, data, (err)=>
                                    return fn(err) if err
                                    _saved()
                                    fn()
                            
                        , (err, popup)=>
                            _popup = popup
                    
                    
                    userlist: (e)->
                        e.open @data.widgets.userlist
                    
                                
            , config
        
        
