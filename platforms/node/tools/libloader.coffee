
##
files = require './files'

##
objects = require '../../../tools/objects'



##
##
_load = (pkg, root, dir, target, handler)->

    _dirs = [root]
    if handler.platform
        _dirs.push files.path.join(root, 'platforms', handler.platform)

    for base in _dirs
        _build pkg, base, dir, target, handler




##
##
_build = (pkg, base, dir, target, handler)->

    if files.fs.existsSync(path = files.path.join base, dir)

        for file in files.fs.readdirSync path
            do(file)=>

                _path = files.path.join base, dir, file

                name = file.substr(0, file.indexOf('.')) || file

                _pkg = pkg+'.'+name

                #console.log '   inspecting file', _path, _pkg

                if files.fs.lstatSync(_path).isDirectory()
                    #console.log '    recursing dir', name, _path

                    if handler.package
                        try
                            handler.package target, name, _path, _pkg
                        catch e
                            (handler.error||console.log) e

                    _build _pkg, base, files.path.join(dir, name), (_target = target[name]||{}), handler
                    _notEmpty(_target) && target[name] = _target

                else if name is 'index'

                    if handler.package
                        try
                            _temp = {}

                            handler.package _temp, name, _path, _pkg.replace('.'+name, '')

                            for key, value of _temp[name]
                                target[key] = value

                        catch e
                            (handler.error||console.log) e

                else
                    #console.log '    building part', _pkg, _path

                    if handler.module
                        try
                            handler.module target, name, _path, _pkg
                        catch e
                            (handler.error||console.log) e


##
##
##
_notEmpty = (obj)->
    !objects.isEmpty obj


##
##
##
module.exports = (dirs, target, handler)->

    ##
    for root in dirs
        #console.log 'loading', root

        target.tools ?= {}
        target.config ?= {}

        _load 'floyd.tools', root, 'tools', target.tools, handler
        _load 'floyd.config', root, 'config', target.config, handler
        _load 'floyd', root, 'lib', target, handler

        if files.fs.existsSync(path = files.path.join root, 'modules') && files.fs.statSync(path).isDirectory()
            for module in files.fs.readdirSync path

                if !handler.modules || handler.modules.indexOf(module) != -1
                    modpath = files.path.join path, module

                    _load ('floyd.tools.'+module), modpath, 'tools', (_target = target.tools[module]||{}), handler
                    _notEmpty(_target) && target.tools[module] = _target

                    _load ('floyd.config.'+module), modpath, 'config', (_target = target.config[module]||{}), handler
                    _notEmpty(_target) && target.config[module] = _target

                    _load ('floyd.'+module), modpath, 'lib', (_target = target[module]||{}), handler
                    _notEmpty(_target) && target[module] = _target

    #console.log 'booted', target
