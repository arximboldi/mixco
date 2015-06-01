mixco.cli
=========

This module implements the meat of the `mixco` script that takes Mixco
scripts and compiles them such that they can be used inside Mixxx.

    _ = require 'underscore'
    path = require 'path'
    fs = require 'fs'
    logger = require 'winston'
    {inspect} = require 'util'

First, we find out what is the name of the script that we are running.

    MIXCO = path.basename process.argv[1]

And then we define some defaults.

    MIXCO_DEFAULT_OUTPUT_DIR = path.join ".", "mixco-output"
    MIXCO_DEFAULT_INPUTS = [ "." ]
    MIXCO_EXT_GLOBS = [
        "*.mixco.js"
        "*.mixco.coffee"
        "*.mixco.litcoffee"
    ]

The `colors` library allows us print colored output.  We shall not
name colors explicitly through our script, but instead only used the
theme names defined here.

    colors = require 'colors/safe'
    colors.setTheme
        data: 'yellow'

The **args** function parses the command line arguments and returns an
object containing the options and arguments, as parsed.  It will also
output and exit when passed `--help`, `--version`, etc...

    args = ->
        _.defaults (require "argp"
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
                #{MIXCO_EXT_GLOBS.join ', '}
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
                    Default: #{MIXCO_DEFAULT_OUTPUT_DIR}"
                metavar: "PATH"
                default: MIXCO_DEFAULT_OUTPUT_DIR
            .option
                short: "r"
                long: "recursive"
                descripton: "Recursively look for scripts in input directories"
            .option
                short: "V"
                long: "verbose"
                description: "Print more output"
            .help()
            .argv()),
            inputs: MIXCO_DEFAULT_INPUTS

The **sources** function takes a list of inputs, as passed by the
user, and returns a list of `gulp` enabled globs that can be passed to
`gulp.src`

    sources = (inputs, recursive) ->
        _.flatten inputs.map (input) ->
            stat = fs.statSync input
            if stat.isDirectory()
                MIXCO_EXT_GLOBS.map (glob) ->
                    if recursive
                        path.join input, "**", glob
                    else
                        path.join input, glob
            else
                [ input ]

The **tasks** function will, given the gulp sources and an output
directory, define all the `gulp` tasks.  It returns the *gulp* module
itself.

    tasks = (sources, output) ->
        gulp = require 'gulp'
        gulp.task 'build', ->
            gulp.src sources
                .pipe gulp.dest output
        gulp

The **main** function finally implements the meat of the command line
script.  It parses the arguments, sets up the logger and starts the
appropiate task.

    exports.main = ->
        argv = args()
        logger.cli()
        logger.level = if argv.verbose then 'debug' else 'info'
        logger.debug "console arguments:", colors.data inspect argv
        logger.info "inputs:", colors.data argv.inputs
        logger.info "output directory:", colors.data argv.output

        srcs = sources argv.inputs, argv.recursive
        logger.debug "gulp sources:", colors.data srcs

        gulp = tasks srcs, argv.output
        gulp.start 'build'
