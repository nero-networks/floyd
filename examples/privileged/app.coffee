##
## running the floyd as root may be important to do some privileged things.
## such as: bind a server to a privileged port or 
##          read sensitive data from a protected file			
## 
## It is possible as long as all the nessecary operations are done
## during the boot sequence. floyd changes the UID/GID on the after:booted
## event. If started as root every floyd.Context will have privileges in early stages:
##
## methods: constructor, configure, boot
## events: before:configured, configured, after:configured,
##         before:booted, booted
## 
## after:booted should be considered as unprivileged. even if the 
## event-handling order calls you before calling the UID switching event-handler
##
## some inline documentation from file 
## ./platforms/node/lib/Platform.coffee line 115: 
##
##    If started as root or with sudo the user and group IDs
##    of the process are resetted to the configured UID/GID.
##
##    If either UID or GID or both are not set the UID/GID
##    which own the app directory are used. 
##
##    CAVEAT: the process will continue to run privileged 
##            if the app directory belongs to root(:root) 
##            and nothing else is configured!
##
module.exports = 
    
    UID: 65534 ## nobody  -  sadly for now only numeric UIDs/GIDs
    GID: 65534 ## nogroup
    
    booted: ()->
            
        @logger.info 'booted privileged' if process.getuid() is 0
        
    started: ()->
        
        @logger.info 'UID:', process.getuid(), 'GID:', process.getgid()

