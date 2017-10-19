

module.exports =

    ##
    ##
    ##
    resolve: (url, dirs=[], next)->
        files = floyd.tools.files

        ## essencial security - strip off all ../../../../ things
        ## so path.join will join it absolute with the public prefix
        ## url = path.normalize('/test/../../../../../../../../etc/hosts')
        ## path.join(floyd.system.appdir, @data.public, url) ==~ ./public/etc/hosts
        ## --> a simple public folder trap

        url = files.path.normalize url.split('?').shift()
        
        if typeof dirs is  'string'
            dirs = [dirs]

        dirs.push files.path.join floyd.system.libdir, 'modules', 'http', 'public'


        for dir in dirs

            if files.fs.existsSync (file = files.path.join dir, url)

                return next null, file

        ## not found!
        next new floyd.error.NotFound url
