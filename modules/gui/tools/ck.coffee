
## coffeescript and fs -less ck clone for callback usage
## no files, no raw coffee.. but it runs in the browser
## and it compiles js functions into kup templates
##
## derrifed from version 0.0.1 of ck
##
## https://github.com/kaleb/ck
## sha: 3b83bb352928a856f92f5fa4dd4a5bdf6aacb7d1
##
## Copyright (c) 2011 James Campos <james.r.campos@gmail.com>
##
## MIT Licensed

#[coffeekup](http://github.com/mauricemach/coffeekup) rewrite

doctypes =
    '1.1':        	'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
    '5':        	'<!DOCTYPE html>'
    'basic':        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">'
    'frameset':        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">'
    'mobile':        '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">'
    'strict':        '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
    'transitional':	'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
    'xml':        	'<?xml version="1.0" encoding="utf-8" ?>'

tagsNormal = 'a abbr acronym address applet article aside audio b bdo big blockquote body button canvas caption center cite code colgroup command datalist dd del details dfn dir div dl dt em embed fieldset figcaption figure font footer form frameset h1 h2 h3 h4 h5 h6 head header hgroup html i iframe ins keygen kbd label legend li map mark menu meter nav noframes noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small source span strike strong style sub summary sup table tbody td textarea tfoot th thead time title tr tt u ul var video wbr xmp'.split ' '
tagsSelfClosing = 'area base basefont br col frame hr img input link meta param'.split ' '


TEMPLATES = {}

module.exports = (code, cached=true)->

    if typeof code is 'function'
        code = '('+code.toString()+').call(this);'

    if !cached || !TEMPLATES[hash = floyd.tools.strings.hash code]

        ##
        html    = null
        indent  = null
        newline = null

        options = {}

        nest = (arg) ->
            if typeof arg is 'function'
                indent += '    ' if options.format
                arg = arg.call options.context
                indent = indent.slice(0, -4) if options.format
                html += "#{newline}#{indent}"

            if arg && !(typeof arg is 'object')
                html += if options.autoescape then esc arg else arg


        compileTag = (tag, selfClosing) ->
            scope[tag] = (args...) ->
                html += "#{newline}#{indent}<#{tag}"

                if typeof args[0] is 'object'
                    for key, val of args.shift()
                        if typeof val is 'boolean'
                            html += " #{key}" if val is true
                        else
                            html += " #{key}=\"#{val}\""

                html += ">"

                return if selfClosing

                nest arg for arg in args

                html += "</#{tag}>"

                return

        scope =
            comment: (str) ->
                html += "#{newline}#{indent}<!--#{str}-->"
                return
            doctype: (key=5) ->
                html += "#{indent}#{doctypes[key]}"
                return
            text: (str)->
                html += str
                return
            raw: (str)->
                html += str
                return
            esc: (str) ->
                str.replace /[&<>"']/g, (c) ->
                    switch c
                        when '&' then '&amp;'
                        when '<' then '&lt;'
                        when '>' then '&gt;'
                        when '"' then '&quot;'
                        when "'" then '&#39;'
            ie: (expr, arg) ->
                html += "#{newline}#{indent}<!--[if #{expr}]>"
                nest arg
                html += "<![endif]-->"
                return

        for tag in tagsNormal
            compileTag tag, false # don't self close

        for tag in tagsSelfClosing
            compileTag tag, true # self close


        handler = new Function 'scope', "with (scope) { #{code}; return }"

        template = (_options, _fn) ->
            options = _options # this is needed, because of some strange scoping behaviour
            fn = _fn           # when using arguments[] (_options) directly.. dunno why :-(
            # if you remove this and use _options directly _options.context is lost inside the
            # template after first tag callback:
            #
            #   p @id               <p>ctx1</p>
            #   div ->              <div>
            #       p @id               <p>undefined</p>
            #                       </div>

            html	= ''
            indent	= ''
            newline = if options.format then '\n' else ''

            handler.call options.context, scope

            if fn
                fn null, html.trim()
            else
                return html.trim()



        ##

        if cached
            TEMPLATES[hash] = template

        return template

    else

        return TEMPLATES[hash]
