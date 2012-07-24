
module.exports =

    ##
    ## @class floyd.Config
    ##
    ##
    class Config
        
        ##
        ##
        ##
        constructor: ()->
                        
            ##
            @data = {}
            
            ##			
            @children = []
            
            ##
            ##
            for item in arguments
                
                if floyd.tools.objects.isArray item
                    for _item in item
                        if _item
                            floyd.tools.objects.extend @, new Config @, _item
                
                ##
                else
                    floyd.tools.objects.extend @, item
            

                i=@children.length
                while --i >= 0
                        
                    ##
                    if typeof (child = @children[i]) is 'string'
                        @children[i] = floyd.tools.objects.resolve(child)
                        
                    ##
                    if !(@children[i] instanceof Config) 
                        @children[i] = new Config @children[i]


