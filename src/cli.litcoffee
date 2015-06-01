mixco.cli
=========

This module implements the meat of the `mixco` script that takes Mixco
scripts and compiles them such that they can be used inside Mixxx.

    _ = require 'underscore'
    path = require 'path'
    fs = require 'fs'
    logger = require 'winston'
    stream = require 'stream'
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
        rename = require 'gulp-rename'

        gulp.task 'scripts', ->
            gulp.src sources
                .pipe browserified()
                .pipe rename extname: ".output.js"
                .pipe gulp.dest output

        gulp.task 'build', [ 'scripts' ]
        gulp

The **browserified()** function returns a gulpy plugin that compiles a
Mixco script (which is a NodeJS script) into a standalone bundle that
can be loaded inside Mixxx.  It also transforms it from Coffee-Script
to JavaScript if necessary, and packages dependencies transparently
(e.g underscore).  This means that a Mixco script can be split across
multiple files.  It is recommended to only use the `.mixco.*`
extension for the main script, where `mixco.script.register` is called.

    browserified = ->
        browserify = require 'browserify'
        through = require 'through2'
        globby = require 'globby'
        thisdir = path.dirname module.filename
        exclude = globby.sync [ path.join thisdir, "*.litcoffee" ]

        through.obj (file, enc, next) ->
            modName =
                path.join (path.dirname file.path),
                    path.basename file.path, path.extname file.path
            scriptName =
                path.basename modName, ".mixco"

            logger.info "compiling:", colors.data file.path
            logger.debug "   module:", colors.data modName
            logger.debug "   script:", colors.data scriptName

            prepend = """
                /*
                 * Script generated with Mixco framework.
                 * http://sinusoid.es/mixco
                 */
                ;MIXCO_SCRIPT_FILENAME = '#{file.path}';
                """

            append  = """
                ;#{scriptName} = require('#{modName}');
                """

            finish = (err, res) ->
                if err
                    logger.error 'browserify:', err
                else
                    file.contents = Buffer.concat [
                        new Buffer prepend
                        res
                        new Buffer append
                    ]
                    next err, file

            entry = new StringStream "require('#{file.path}');"

            exclude.reduce ((b, fname) -> b.exclude fname),
                    browserify entry,
                        extensions: [ ".js", ".coffee", ".litcoffee"]
                .exclude 'coffee-script/register'
                .require modName
                .bundle finish

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


    class StringStream extends stream.Readable
        constructor: (@str) ->
            super()

        _read: (size) ->
            @push @str
            @push null
