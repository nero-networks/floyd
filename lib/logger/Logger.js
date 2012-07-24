/*
 * class Logger
 */

var _lastId = null;

module.exports = function Logger(id) {
    
    
    var LINE_FORMAT = "%s%d-%02d-%02d %02d:%02d:%02d.%0-3d - %s",
    Level = {
        OFF		: (-1 >>> 1),				
        SEVERE	: 1000,
        WARNING	: 900,
        INFO	: 800,
        DEBUG	: 700,
        CONFIG	: 650,
        STATUS	: 600,
        FINE	: 500,
        FINER	: 400,
        FINEST	: 300,
        ALL		: -((-1 >>> 1)+1)
    };
    for(var key in Level)
        Level[Level[key]] = key;

    var actLevel = Level.INFO,
        slaves = {}, slave_id = 1;

    return {
        Level: Level,

        log: log,
        error: error,

        severe:	function() { _log(Level.SEVERE, arguments); },
        warning:function() { _log(Level.WARNING, arguments); },
        info:	function() { _log(Level.INFO, arguments); },
        status:	function() { _log(Level.STATUS, arguments); },
        debug:	function() { _log(Level.DEBUG, arguments); },
        config:	function() { _log(Level.CONFIG, arguments); },
        fine:	function() { _log(Level.FINE, arguments); },
        finer:	function() { _log(Level.FINER, arguments); },
        finest:	function() { _log(Level.FINEST, arguments); },

        level: function(level) { if(level) actLevel = level; return actLevel; },	
        isLoggable : isLoggable,
        
        addSlave: addSlave,
        removeSlave: removeSlave
    };

    function isLoggable(level) {
        if(typeof level === 'string')
            level = Level[level]
        return (level >= actLevel);
    }
    
    function addSlave(slave) {
        if(!slave.log)
            throw new Error("not logger slave!");
            
        if(!slave.id)
            slave.id = "ls-"+slave_id++;		
        slaves[slave.id] = slave;
    }
    
    function removeSlave(slave) {
        if(slave.id && slaves[slave.id])
            delete slaves[slave.id];
    }
    
    function log() {
        
        // allways call the slaves and let them decide
        for(var id in slaves)
            slaves[id].log.apply(slaves[id], arguments);
            
        var level = parseInt(arguments[0]);
        
        if(level >= actLevel && level < Level.OFF) {
            
            if(console)
                _console.apply(this, arguments);			
        }
    }

    function error() {
        for(var i=0; i<arguments.length; i++) {
            if( !((err = arguments[i]) instanceof Error) ) {
                try {throw new Error(err.message)} catch(e) {err=e}
            }
            _log(Level.SEVERE, [err]);
        }
    }

    function _log(level, args) {
        Array.prototype.unshift.call(args, parseInt(level));
        log.apply(this, args);
    }

    function _console() {
        
        var date = new Date(),
            level = Level[Array.prototype.shift.call(arguments)];
        
        var method;
        switch(level) {
            case "SEVERE" : method = "error"; break;
            case "WARNING" : method = "warn"; break;
            case "INFO" : method = "info"; break;
            default : method = "log"; break;
        }
        
        var _lf = _lastId ? '\n' : ''
        arguments[0] = floyd.tools.strings.sprintf(LINE_FORMAT,
            ((_lastId != id && (_lastId = id)) ? _lf+id+'\n' : ''),
            date.getFullYear(), date.getMonth()+1, date.getDate(),
            date.getHours(), date.getMinutes(), date.getSeconds(),
            date.getMilliseconds(), arguments[0])
        
        console[method].apply(console, arguments);
        
    }
};
