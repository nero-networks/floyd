
module.exports = SearchableMap = (data, parent)->
    return SearchableMap.call(data, data, parent) if data isnt @
            
    ## find with recursive parent lookup
    @find = (key, deflt)=>
        
        if key is 'find'
            throw new floyd.error.Exception "don't use find as a SearchableMap key! its the name of the search function..." 
        
        ## 1.
        if (val = floyd.tools.objects.resolve key, @) isnt undefined
            return val
                
        ## 2. parent
        if parent?.find
            return parent.find key, deflt
                    
        ## fallback
        return deflt
    
    return @		
