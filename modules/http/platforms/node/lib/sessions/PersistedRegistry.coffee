
module.exports =

    class PersistedRegistry extends floyd.http.sessions.Registry

        ##
        ##
        ##
        constructor: (_config, parent)->
            super _config, parent
            @_config = _config
            @__store = @_config.store || '.floyd/sessions-store.json'

            if !floyd.tools.files.exists @__store
                floyd.tools.stores.write 'registry', {}, @__store

                if process.getuid() is 0
                    floyd.tools.files.chown @__store, floyd.system.UID, floyd.system.GID

            floyd.tools.objects.process floyd.tools.stores.read('registry', @__store),

                each: (id, data, next)=>

                    sess = new (floyd.tools.objects.resolve @_config.sessions.type) id, @_config.sessions

                    floyd.tools.objects.extend sess, data

                    sess.touch()

                    @add sess

                    next()

                done: (err)=>
                    throw err if err

                    floyd.tools.stores.write 'registry', {}, @__store

                    parent.on 'shutdown', ()=>
                        floyd.tools.stores.write 'registry', @_pool, @__store
