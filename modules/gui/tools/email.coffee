
module.exports = 

    obfuscate: (ele, done)->				
                
        ##
        encode = ele.find('a[href*="mailto:"]')
        decode = ele.find('a[href*="_contact/"]')
        
        _fake = (addr)->
            addr.replace(/[.]/g, ' ').replace(/[-]/g, ' - ').replace('@', ' at ')
        
        ##
        encode.each (i, ele)->
            link = $ ele
            
            href = link.attr('href')
            addr = href.substr 7
            
            link.attr 'href', href.replace('mailto:', '_contact/').replace(/[.]/g, '+').replace('@', '/')
            link.attr 'rel', 'nofollow'
            
            if link.text() is addr
                link.text _fake addr
        
        ##
        decode.each (i, ele)->
            link = $ ele
            
            href = link.attr('href').replace('_contact/', 'mailto:').replace(/[+]/g, '.').replace('/', '@')
            addr = href.substr 7
            
            link.attr 'href', href
            link.attr 'rel', null
            
            if link.text() is _fake addr
                link.text addr
        
        done?()