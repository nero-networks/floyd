
module.exports =

    ##
    ##
    ##
    class FileStore extends floyd.stores.Store

        ##
        ##
        ##
        init: (options, done)->
            super options, (err)=>
                return done(err) if err

                _dir = options.path ? floyd.tools.files.path.join '.floyd', 'data', 'stores'

                if !floyd.tools.files.exists _dir
                    floyd.tools.files.mkdir _dir, 0o700

                @_dataFile = floyd.tools.files.path.join _dir, options.name+'.data'
                if floyd.tools.files.exists @_dataFile
                    @_memory = JSON.parse floyd.tools.files.read @_dataFile, 'utf-8',

                done()

        ##
        ##
        ##
        persist: (done)->
                ## only persist if not readonly
            if !@_options.readonly
                indent = if @_options.find('debug') then 4 else 0

                floyd.tools.files.write @_dataFile, JSON.stringify @_memory, null, indent

            super done
