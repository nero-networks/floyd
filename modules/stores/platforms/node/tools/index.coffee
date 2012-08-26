
module.exports =
    
    
    ##
    ##
    ##
    context: (id, type, config)->
    
        new floyd.Config
            id: id
            
            type: 'stores.Context'
            
            data: 
                type: type
        
        , config
    
    
    
    ##
    ##
    ##	
    read: (key, file='.floyd/default-store.json')->
        
        floyd.tools.objects.resolve key, _read(file) || {}
        
        
        
    ##
    ##
    ##
    write: (key, value, file='.floyd/default-store.json')->
        _data = data = _read(file) || {}
        
        keys = key.split '.'
        while keys.length > 1 && _data[keys[0]]
            _data = _data[keys.shift()]
            
        _data[keys.shift()] = value
        
        _write file, data
    


##
##
##
_read = (file)->

    if floyd.tools.files.fs.existsSync file

        JSON.parse floyd.tools.files.fs.readFileSync file, 'utf-8'
    

##
##
##
_write = (file, data)->

    json = JSON.stringify data, null, 4
        
    floyd.tools.files.fs.writeFileSync file, json, 'utf-8'
