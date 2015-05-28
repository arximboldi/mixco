
mixco.cli
=========

    path = require 'path'

    MIXCO = path.basename process.argv[1]
    MIXCO_OUTPUT_DIR = "./mixco-output"
    MIXCO_EXT = [
        "*.mixco.js"
        "*.mixco.coffee"
        "*.mixco.litcoffee"
    ]

    args = ->
        require "argp"
        .createParser once: true
        .readPackage path.join __dirname, "..", "package.json"
        .allowUndefinedArguments()
        .usages [ "#{MIXCO} [options] [<input>...]" ]
        .on "argument", (argv, argument) ->
            argv.inputs ?= []
            argv.inputs.push argument
        .body()
        .text "
            This program can compile all the <input> Mixco scripts
            into .js and .xml files that can be used inside Mixxx.
            Mixco scripts have one of the following extensions:
            #{MIXCO_EXT.join ', '}
            \n
            \nWhen no <input> is passed, it will compile all scripts
            in the current directory. When an <input> is a directory,
            all scripts found in it will be compiled."
        .text()
        .text " Options:"
        .option
            short: "o"
            long: "output"
            description: "Directory where to put the generated files.
                Default: #{MIXCO_OUTPUT_DIR}"
            default: MIXCO_OUTPUT_DIR
        .help()
        .argv()

    exports.main = ->
        argv = args()
        console.log argv
