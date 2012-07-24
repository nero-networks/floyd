
module.exports = 

    ##
    ##
    ##
    class MappedCollection extends Array
    
        ##
        ##
        ##
        constructor: (list=[], _id)->
            super()
            
            _push = @push
            @push = (child, _id='id')->				
                if @indexOf(child) is -1
                    _push.apply @, [child]
                    
                if !@[child[_id]]
                    @[child[_id]] = child
                    
                #console.log 'push', @length
            
            for child in list
                @push child, _id
            
        ##
        ##
        ##
        delete: (child, _id='id')->
            
            #console.log 'delete', child[_id]
            
            if ( idx = @indexOf child ) isnt -1
                @splice idx, 1
                delete @[child[_id]]
                
