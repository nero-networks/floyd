
class TestStoresContext extends floyd.stores.Context

    ##
    prepareTests: (fn)->
        @_process [
            id: 'item1'
            type: 'type1'
            txt: 'txt1'
        ,
            id: 'item2'
            type: 'type2'
            txt: 'txt1'
        ,
            id: 'item3'
            type: 'type3'
            txt: 'txt1'
        ,
            id: 'item4'
            type: 'type4'
            txt: 'txt2'
        ],
            each: (item, next)=>
                @set item.id, item, next
            done: fn

    ##
    cleanupTests: (fn)->
        fn()

    ##
    testGet: (fn)->
        @get 'item3', (err, item)=>
            return fn(err) if err

            if item.type isnt 'type3'
                return fn new Error 'expected type3 got '+item.type

            return fn()

    ##
    testSet: (fn)->
        item =
            id: 'item3'
            type: 'type2'
            txt: 'txt3'


        @set item.id, item, (err)=>
            return fn(err) if err
            @get 'item3', (err, saved)=>
                return fn(err) if err
                if saved.type isnt 'type2'
                    return fn new Error 'expected type2 got '+saved.type
                fn()

    ##
    testHas: (fn)->
        @has 'item4', (err, has)=>
            return fn(err) if err
            if !has
                return fn new Error 'expected item4 but not found'
            fn()

    ##
    testRemove: (fn)->
        @remove 'item4', (err)=>
            return fn(err) if err
            @testHas (err)=>
                return fn new Error('expected no result but found item4') if !err
                fn()

    ##
    testFind: (fn)->
        @_createFindQuery (query, expect)=>
            @find query,
                sort:
                    type: 1
            , null, (err, items)=>
                return fn(err) if err

                for item in items
                    if expect.indexOf(item.type) is -1
                        return fn new Error 'expected '+expect.join(',')+' but got '+item.type
                fn()

    ##
    _createFindQuery: (fn)->
        fn {}, ['type1', 'type2', 'type4', 'type5']


##
##
##
class MongoTestStoresContext extends TestStoresContext

    ##
    _createFindQuery: (fn)->
        fn {type: $ne: 'type1'}, ['type2', 'type4', 'type5']

    ##
    testDistinct: (fn)->
        @distinct 'txt', {}, (err, types)=>
            return fn(err) if err

            expect = ['txt1', 'txt2']
            for type in types
                if expect.indexOf(type) is -1
                    return fn new Error 'expected '+expect.join(',')+' but got '+type
            fn()

    ##
    cleanupTests: (fn)->
        @_engine._db?.dropDatabase()
        @_engine.close fn

##
##
##


DBNAME = 'tests'+(+new Date())

module.exports =
    id: 'stores'

    type: 'floyd.TestContext'

    data:
        logger:
            level: 'INFO'

    children: [
        id: 'memory'
        type: TestStoresContext
    ,
        id: 'object'
        type: TestStoresContext
        data:
            type: 'object'
    ,
        id: 'file'
        type: TestStoresContext
        data:
            type: 'file'
            path: '.floyd/tmp/'
            name: DBNAME
    ,
        id: 'mongodb'
        type: MongoTestStoresContext
        data:
            type: 'mongo'
            name: DBNAME
            collection: 'tests'
            index: ['id']

    ]
