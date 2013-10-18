
md = require 'markdown'

ALLOWEDTAGS = ['a', 'b', 'table', 'tr', 'th', 'td', 'br', 'div', 'header', 'footer', 'section', 'article', 'nav', 'address']

FINDTAGS = /(<p>)?&lt;([\/]?)(a|b|table|tr|th|td|br|div|header|footer|section|article|nav|address)(.*?)( [\/])?&gt;(<\/p>)?/g

REPLACETAG = /(<p>)?&lt;([\/]?)(a|b|table|tr|th|td|br|div|header|footer|section|article|nav|address)(.*?)( [\/])?&gt;(<\/p>)?/

MODIFIER = /^{:([ ]+)?([a-z]+)?(\.|#)?(.*?)}/

module.exports = parse = (input, _options, fn)->
    options = _options
        
    if typeof options is 'function'
        [options, fn] = [fn, options]
    
    if !input
        return if fn then fn(null, '') else '' 

    options ?= {}
    
    dialect = floyd.tools.objects.cut options, 'dialect', 'Maruku'
    
    _tags = 
        __i: 0
        
    options.preprocessTreeNode = (jsonml)->
        
        if typeof jsonml[1] is 'string'
            
            if match = jsonml[1].match MODIFIER			
            
                jsonml[1] = jsonml[1].replace match[0], ''
                            
                if (tag = match[2]) && ALLOWEDTAGS.indexOf(tag) != -1
                    
                    jsonml[0] = tag
                    
                    if !floyd.tools.objects.isObject jsonml[1]					
                        jsonml.splice 1, 0, {}
                    
                    attribs = jsonml[1]
                    
                    classes = encodeURIComponent(match[4] || '').split('.')
                    
                    if match[3] is '#'
                        attribs.id = classes.shift()
                    
                    if classes.length && classes[0]		
                        attribs.class = classes.join(' ')			
                    
                                    
        return jsonml
        

    ## fire
    fn ?= (e, d)-> if e then throw e else return d

    if input
        input = input.replace /\r/g, ''

        html = md.parse(input, dialect, options) 
        
        if match = html.match(FINDTAGS)
            for i in [0..match.length]
                html = html.replace REPLACETAG, '<$2$3$4$5>'
    else 
        html = ''
    
    #console.log html
    
    fn null, html
    
    return html
    
