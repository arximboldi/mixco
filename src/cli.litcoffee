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

We use the `package.json` data to get the script metadata.

    packageJsonPath =  path.join __dirname, "..", "package.json"
    package_ = JSON.parse fs.readFileSync packageJsonPath
    MIXCO_VERSION = package_.version
    MIXCO_AUTHOR = package_.author
    MIXCO_DESCRIPTION = package_.description
    MIXCO_HOMEPAGE = package_.homepage

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
            .allowUndefinedArguments()
            .usages [ "", "#{MIXCO} [options] [<input>...]" ]
            .on "argument", (argv, argument) ->
                argv.inputs ?= []
                argv.inputs.push argument
            .body()
            .text MIXCO_DESCRIPTION
            .text "\n
                This program can compile all the <input> Mixco scripts
                into .js and .xml files that can be used inside Mixxx.
                Mixco scripts have one of the following extensions:
                #{MIXCO_EXT_GLOBS.join ', '}. When no <input> is
                passed, it will compile all scripts in the current
                directory. When an <input> is a directory, all scripts
                found in it will be compiled."
            .text()
            .text "Options:"
            .option
                short: "o"
                long: "output"
                description: "Directory where to put the generated files
                    Default: #{MIXCO_DEFAULT_OUTPUT_DIR}"
                metavar: "PATH"
                default: MIXCO_DEFAULT_OUTPUT_DIR
            .option
                short: "r"
                long: "recursive"
                description: "Recursively look for scripts in input directories"
            .help()
            .option
                short: "V"
                long: "verbose"
                description: "Print more output"
            .version(MIXCO_VERSION)
            .text "\nMore info and bug reports at: <#{MIXCO_HOMEPAGE}>"
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
                .pipe logging "generated"
                .pipe gulp.dest output

        gulp.task 'mappings', ->
            gulp.src sources
                .pipe xmlMapped()
                .pipe rename extname: ".output.midi.xml"
                .pipe logging "generated"
                .pipe gulp.dest output

        gulp.task 'build', [ 'scripts', 'mappings' ]
        gulp

We define a couple of helpers to extract parts of a path pointing to a
Mixco script file.

    moduleName = (scriptPath) ->
        path.join (path.dirname scriptPath),
            path.basename scriptPath, path.extname scriptPath

    scriptName = (scriptPath) ->
        path.basename (moduleName scriptPath), ".mixco"

    logging = (str) ->
        through = require 'through2'
        through.obj (file, enc, next) ->
            logger.info "#{str}:", colors.data file.path
            next null, file

The **xmlMapped** gulpy plugin generates the `.midi.xml` Mixxx
controller mapping files.

    xmlMapped = ->
        through = require 'through2'
        (require 'require.async') require

        through.obj (file, enc, next) ->
            moduleName_ = moduleName file.path
            scriptName_ = scriptName file.path
            logger.debug "compiling mapping for:", colors.data moduleName_
            logger.debug "    module:", colors.data moduleName_
            logger.debug "    script:", colors.data scriptName_
            require.async moduleName_, (exports) ->
                config = exports[scriptName_].config()
                file.contents = new Buffer config
                # This is being generated by heterarchy
                delete Object::__mro__
                next null, file

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
            moduleName_ = moduleName file.path
            scriptName_ = scriptName file.path
            logger.debug "compiling script for:", colors.data file.path
            logger.debug "    module:", colors.data moduleName_
            logger.debug "    script:", colors.data scriptName_

            prepend = new Buffer """
                /*
                 * File generated with Mixco framework version: #{MIXCO_VERSION}
                 * More info at: <#{MIXCO_HOMEPAGE}>
                 */
                \nMIXCO_SCRIPT_FILENAME = '#{file.path}';\n\n
                """
            append  = new Buffer """
                \n#{scriptName_} = require('#{moduleName_}');
                /* End of Mixco generated script */
                """
            finish = (err, res) ->
                if err
                    logger.error 'browserify:', err
                else
                    file.contents = Buffer.concat [
                        prepend, res, append ]
                    next err, file

            bundler = browserify (toStream "require('#{file.path}');"),
                extensions: [ ".js", ".coffee", ".litcoffee"]
            exclude.reduce ((b, fname) -> b.exclude fname), bundler
                .exclude 'coffee-script/register'
                .require moduleName_
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

Oh, and there is this utility to create a stream from a plain string.

    class StringStream extends stream.Readable
        constructor: (@str) ->
            super
        _read: (size) ->
            @push @str
            @push null

    toStream = (str) -> new StringStream str
