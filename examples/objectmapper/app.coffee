
module.exports =

    running: ->

        ## given some arbitrary data...
        data =
            a:
                b: [
                    x: 1
                ,
                    x: 2
                ,
                    x: 3
                ]

                c: ['h', 'a', 'l', 'l', 'o']

                d: '1234;4321;5678;8765'

                foo: 'Allem'


                bla:
                    method1: 'foo_bar_buzz'
                    method2: 'some_other_buzz'

                nt:
                    wo:
                        rt: 42

        ## define a mapping object referencing the data structures keys as dotted path to the value
        map =
            foo:
                XofAB: ['a.b[0].x', 'a.b[1].x', 'a.b[2].x']
                list: 'a.b'
                obj: 'a.b[1]'
                char: 'a.foo[3]'

            numbers: $split: ';': 'a.d'

            camelized: $camelize: ['a.bla.method1', 'a.bla.method2']

            squares: $square: [1, 2, 3, 4, 5]

            hello:
                german: $join: '': 'a.c'
                spanish: $format: '%s%s%s%s': ['a.c[0]', 'a.c[4]', 'a.c[2]', 'a.c[1]']

            text:
                $format: 'Die $1 auf die Frage nach %s ist %s': ['a.foo', 'a.nt.wo.rt']

        ## declare some $custom commands in addition to the predefined $split, $join, $format
        commands =
            camelize: (value, data, commands)->
                out = ''
                for part in floyd.tools.objects.resolve(value, data, commands).split '_'
                    out += if !out then part else floyd.tools.strings.capitalize part
                return out

            square: (value)->
                return value * value

        ## execute
        mapped = floyd.tools.objects.map data, map, commands

        console.log floyd.tools.objects.flatten mapped

        ## dump mapped object
        console.log JSON.stringify mapped, null, 2

        ## ... investigate your console output
