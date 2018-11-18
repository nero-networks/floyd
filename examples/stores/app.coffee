
module.exports =

    children: [

        ##
        ## simple in-memory key-value store with basic search engine
        ##

        id: 'demostore'

        type: 'stores.Context'

        memory:
            'key1':
                id: 'key1', count: 1, text: 'value1', price: 9.95

            'key2':
                id: 'key2', count: 10, text: 'value2', price: 12.95


    ]

    running: ->

        ##
        ## lookup the stores context
        ## (you just need the id relative to the common parent to do this from anywhere)
        ##

        @lookupLocal 'demostore', (err, store)=>
            return @logger.error(err) if err

            ## store a new item

            store.set 'key3',
                id: 'key3', count: 7, text: 'value3', price: 3.95

            ## read an item

            store.get 'key1', (err, item)=>
                return @logger.error(err) if err

                item.price = 11.49

                ## save the item

                store.set 'key1', item, (err)=>
                    return @logger.error(err) if err

                    ## search the data

                    store.find
                        text: '.*1$' ## matches all items where text ends with 1
                        price: '>': 10 ## matches all items where price is higher than 10

                    , {}, ['text', 'price'], (err, items)=>
                        return @logger.error(err) if err

                        for item in items
                            @logger.info item.text+': '+item.price
