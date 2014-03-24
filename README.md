# Floyd!

A hierarchical app container

## Installation

### npm

Install with [npm](http://github.com/isaacs/npm):

    not published yet!
    
### git

    mkdir ~/projects/
    cd ~/projects/
    git clone https://github.com/nero-networks/floyd.git

#### Prepare your System for the git installation

* You'll need the [node](http://nodejs.org/) engine **>= 0.10.26 ** to run floyd

* Symlink `~/projects/floyd/bin/floyd` somehow into $PATH (e.g. /usr/local/bin/)

* You need a `node_modules` folder somewhere above or within your projects folder 
  with the floyd folder symlinked into.

        mkdir ~/projects/node_modules
        cd ~/projects/node_modules
        ln -s ../floyd
     
* Build the modules and install the dependencies.

        cd ~/projects/floyd
        floyd build
        
        
## First Steps

Put a symbolic link to `~/projects/floyd/bin/floyd` into your execution PATH. 
I simply symlinked it into `/usr/local/bin` (which is in my $PATH variable)

    cd /usr/local/bin/
    sudo ln -s ~/projects/floyd/bin/floyd 

### Floyd`s Hello World 

* change to the `~/projects/floyd/examples/basics` directory 
  and type **floyd**. this opens the app controll interface: 
        
          
                                          _/_/_/_/  _/                            _/
        [S]tart         [H]elp           _/        _/    _/_/    _/    _/    _/_/_/ 
        [K]ill          [C]lear         _/_/_/    _/  _/    _/  _/    _/  _/    _/  
        [B]uild         [D]ump log     _/        _/  _/    _/  _/    _/  _/    _/   
        [U]pdate                      _/        _/    _/_/      _/_/_/    _/_/_/    
                        [Q]uit           (c) 2012 Nero Networks    _/               
                                                                _/_/
    
* then press `s` and you'll get something like this:

        starting basics
        WARNING: <Ctrl-c> will terminate the child-process!
                 use [Q]uit to quit this log-viewer session...
        basics - (floyd.Context)
        2012-06-07 19:13:48.736 - status changed to configured
        2012-06-07 19:13:48.751 - status changed to booted
        2012-06-07 19:13:48.751 - status changed to started
        2012-06-07 19:13:48.751 - Hello World!
        2012-06-07 19:13:48.752 - status changed to running
        2012-06-07 19:13:48.752 - status changed to shutdown
        2012-06-07 19:13:48.752 - status changed to stopped
    
    
### My First TestApp

* Create a new floyd project by executing
    
        floyd create testapp  <-- choose any name you like
    
* Change to the new created directory
    
        cd testapp            <-- use your choosen name!

* Copy the file app.coffee from the basics example
    
        cp ~/projects/floyd/examples/basics/app.coffee .

* Open the app interface
    
        floyd                 <-- opens the app interface
    
* Start the app by pressing the `s`-key


## More

Take a look into the [examples](examples/) folder. There are many examples including

### basic floyd features
- [**basics**](examples/basics/) - a very basic configuration. this is the HelloWorld example
- [**modules**](examples/modules/) - the helloworldHelloWorld module demo
- [**platforms**](examples/platforms/) - simple platform dependent code demo
- [**privileged**](examples/privileged/) - changes the UID/GID if started as root

### webservers
- [**webserver**](examples/webserver/) - a basic webserver with statics, E-Tags and gzip compression
- [**ssl-webserver**](examples/ssl-webserver/) - https protected webserver
- [**connect**](examples/connect/) - a demonstration how to use the connect module with floyd

### html gui generator
- [**gui**](examples/gui/) - a serverside-rendered gui HelloWorld

### (remote-)inter process commiunication with dnode
- [**dnode**](examples/dnode/) - a simple dnode Bridge demo

### server with gui and dnode
- [**auth**](examples/auth/) - uses http, gui and dnode to realise an authenticated environment
- [**chat**](examples/chat/) - a tiny pubsub chat. made with dnode bridges
- [**cluster**](examples/cluster/) - communication of two floyd processes with dnode bridges

### RpcServer communicates by simple http requests
- [**omarpc**](examples/omarpc/) - RPC Server with simple protocoll
