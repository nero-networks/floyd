
module.exports = (parent, config, fn)->

    if typeof config is 'function'
        fn = config
        config = {}

    if !fn
        fn = (err)=>
            parent.error(err) if err && parent.error


    ##
    _id = config?.id || parent.__ctxID()

    ##
    ##
    config = new floyd.Config

        id: _id

        type: 'gui.widgets.Popup'

    , config



    ##
    ##
    try
        parent._createChild config, (err, child)=>
            fn(err, child)

            child.on 'close', (e)->

                child.confirmClose ()=>

                    if child.data.fade
                        child.__root.fadeOut 'fast', ()=>
                            child.__root.remove()
                    else
                        child.__root.remove()

                    child.stop ()->
                        #console.log 'stopped', child.ID

                        parent.children.delete child

                        parent.once 'destroyed', ()->

                            child.destroy ()->

                                #console.log 'destroyed', child.ID

                return false


    catch err
        alert 'Error: '+err.message
        console.log err
