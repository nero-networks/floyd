
module.exports =

    class UserContext extends floyd.Context

        ##
        configure: (config)->
            super new floyd.Config
                id: 'userbackend'

                data:
                    list:
                        fields: ['login', 'name', 'lastlogin', 'roles', 'email', 'active']
                        sort:
                            name: 1

                permissions:

                    list:
                        roles: ['admin']

                    del:
                        roles: ['admin']

                    load:
                        check: (identity, key, [login], next)=>
                            @_checkLogin identity, login, next

                    save:
                        check: (identity, key, [data], next)=>
                            @_checkLogin identity, data.login, next

            , config


        ##
        ##
        ##
        list: (offset, limit, fn)->
            @parent.children.users.find {},

                offset: offset
                limit: limit
                sort: @data.list.sort

            , @data.list.fields, (err, items, data)=>
                return fn(err) if err

                active = []
                inactive = []

                for item in items
                    if item.active
                        active.push item
                    else
                        inactive.push item

                fn null, active.concat(inactive), data


        ##
        ##
        ##
        load: (login, fn)->
            @parent.children.users.get login, (err, user)=>
                return fn(err) if err || !user

                user = floyd.tools.objects.clone user,
                    login: login

                delete user.pass

                fn null, user


        ##
        ##
        ##
        save: (data, fn)->
            @parent.children.users.get data.login, (err, saved)=>
                return fn(err) if err

                if !data.pass && saved?.pass
                    data.pass = saved.pass

                @parent.children.users.set data.login, data, fn

        ##
        ##
        ##
        del: (login, fn)->
            return fn(new Error 'no username provided') if !login
            @parent.children.users.remove login, fn

        ##
        ##
        ##
        _checkLogin: (identity, login, next)->
            identity.hasRole 'admin', (err, isAdmin)=>
                return next(false) if err
                return next(true) if isAdmin

                identity.login (err, _login)=>
                    return next(false) if err || !_login || _login isnt login

                    next true
