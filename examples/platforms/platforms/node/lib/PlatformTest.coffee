
module.exports =

    class NodePlatformTest extends floyd.Context
    
        start: (fn)->
            super fn
            
            versions = ''
            for p, v of process.versions
                if p isnt 'node'
                    versions += p+'-'+v+' '
            
            @logger.info 'Platform: NodeJS-%s (%s)', process.versions.node, versions
            