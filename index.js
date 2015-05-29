// mixco
// =====

if (process.env.MIXCO_USE_SOURCE) {
    require('coffee-script/register')
    module.exports = {
        behaviour: require('./src/behaviour'),
        control: require('./src/control'),
        script: require('./src/script'),
        transform: require('./src/transform'),
        util: require('./src/util'),
        value: require('./src/value')
    }
} else {
    module.exports = {
        behaviour: require('./lib/behaviour'),
        control: require('./lib/control'),
        script: require('./lib/script'),
        transform: require('./lib/transform'),
        util: require('./lib/util'),
        value: require('./lib/value')
    }
}
