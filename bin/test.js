floyd = require('floyd');

app = new floyd.Config({
    type: 'TestContext',
    data: {
        logger: {
            level: 'INFO'}}

}, function() {
    this.children.push(require('../modules/stores/tests'));
});

floyd.init(app, function(err, ctx) {
    if(err) return console.error(err)
    ctx.runTests(function(err) {
        if(err) return console.error(err);
    });
});
