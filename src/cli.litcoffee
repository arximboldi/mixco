mixco.cli
=========

> This file is part of the [Mixco framework](http://sinusoid.es/mixco).
> - **View me [on a static web](http://sinusoid.es/mixco/src/cli.html)**
> - **View me [on GitHub](https://github.com/arximboldi/mixco/blob/master/src/cli.litcoffee)**

This module implements the meat of the `mixco` script that takes Mixco
scripts and compiles them such that they can be used inside Mixxx.

    require 'coffee-script/register'
    _ = require 'underscore'
    path = require 'path'
    fs = require 'fs'
    logger = require 'winston'
    stream = require 'stream'
    promise = require 'node-promise'
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
            .option
                short: "w"
                long: "watch"
                description: "Watch scripts for changes and recompile them"
            .option
                short: "T"
                long: "self-test"
                description: "Test the framework before compilation"
            .option
                short: "t"
                long: "test"
                description: "Test the input scripts before compilation"
            .option
                long: "factory"
                description: "Compile the scripts that come with Mixco"
            .option
                long: "fatal-tests"
                description: "Make process fail when tests fail"
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

    tasks = (sources, output, opts={}) ->
        gulp = require 'gulp'
        cached = require 'gulp-cached'
        rename = require 'gulp-rename'

        testError = ->
            logger.error arguments...
            if opts.fatal_tests
                process.exit 1

        gulp.task 'self-test', ->
            if opts.self_test
                mocha = require 'gulp-mocha'
                specs = path.join __dirname, '..', 'test', 'mixco', '*.spec.coffee'
                logger.info "testing framework:", colors.data specs
                gulp.src specs, read: false
                    .pipe mocha()
                    .on 'error', testError

        gulp.task 'test', ['self-test'], ->
            if opts.test
                mocha = require 'gulp-mocha'
                specs = path.join __dirname, '..', 'test', 'scripts.spec.coffee'
                logger.info "testing input scripts:", colors.data specs
                process.env.MIXCO_TEST_INPUTS = sources.join ':'
                gulp.src specs, read: false
                    .pipe mocha()
                    .on 'error', -> testError

        gulp.task 'scripts', ['test'], ->
            ext = ".output.js"
            gulp.src sources
                .pipe cached 'scripts'
                .pipe changed output, ext
                .pipe browserified()
                .pipe rename extname: ext
                .pipe gulp.dest output
                .pipe logging "generated"

        gulp.task 'mappings', ['test'], ->
            ext = ".output.midi.xml"
            gulp.src sources
                .pipe cached 'sources'
                .pipe changed output, ext
                .pipe xmlMapped()
                .pipe rename extname: ext
                .pipe gulp.dest output
                .pipe logging "generated"

        gulp.task 'build', [ 'scripts', 'mappings' ]
        gulp.task 'watch', ['build'], -> gulp.watch sources, [ 'build' ]
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

    changed = (dest, ext) ->
        changed_ = require 'gulp-changed'
        changed_ dest,
            extension: ext
            hasChanged: (stream, next, file, path) ->
                fs.stat path, (err, stat) ->
                    if err or file.stat.mtime > stat.mtime
                        stream.push file
                    else
                        logger.info "up to date:", colors.data path
                    do next

The **xmlMapped** gulpy plugin generates the `.midi.xml` Mixxx
controller mapping files.

    consume = (stream) ->
        result = new promise.Promise
        chunks = []
        stream.on 'data', (chunk) ->
            chunks.push chunk
        stream.on 'end', ->
            result.resolve Buffer.concat chunks
        stream.on 'error', (err) ->
            result.reject error
        result

    fork_ = (what, args) ->
        childp = require 'child_process'
        proc = childp.fork what, args, silent: true
        stdoutResult = consume proc.stdout
        exitResult = new promise.Promise
        proc.on 'error', (err) ->
            logger.error err
            next err, null
        proc.on 'exit', (code) ->
            if code == 0
                exitResult.resolve code
            else
                exitResult.reject new Error "Exit code: #{code}"
        promise.allOrNone stdoutResult, exitResult

    xmlMapped = ->
        through = require 'through2'
        through.obj (file, enc, next) ->
            moduleName_ = moduleName file.path
            scriptName_ = scriptName file.path
            logger.debug "compiling mapping for:", colors.data moduleName_
            logger.debug "    module:", colors.data moduleName_
            logger.debug "    script:", colors.data scriptName_
            fork_ file.path, [ "-g" ]
                .then ([data, _]) ->
                        file.contents = data
                        next null, file
                    , (err) ->
                        logger.error "Error while generating mapping from:",
                            colors.data file.path
                        logger.error err

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
                \n#{scriptName_} = require('#{moduleName_}').#{scriptName_};
                /* End of Mixco generated script */
                """
            finish = (err, res) ->
                if err
                    logger.error 'Error while generating script for:',
                        colors.data file.path
                    logger.error err
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
appropriate task.

    exports.main = ->
        argv = args()
        logger.cli()
        logger.level = if argv.verbose then 'debug' else 'info'
        logger.debug "console arguments:\n", colors.data inspect argv
        logger.info "inputs:", colors.data argv['inputs']
        logger.info "output directory:", colors.data argv['output']

        if argv['factory']
            argv['inputs'].push path.join __dirname, '..', 'script'
        srcs = sources argv['inputs'], argv['recursive']
        logger.debug "gulp sources:", colors.data srcs

        gulp = tasks srcs, argv.output,
            self_test: argv['self-test']
            test: argv['test']
            fatal_tests: argv['fatal-tests']

        task = if argv['watch'] then 'watch' else 'build'
        gulp.start task

Oh, and there is this utility to create a stream from a plain string.

    class StringStream extends stream.Readable
        constructor: (@str) ->
            super
        _read: (size) ->
            @push @str
            @push null

    toStream = (str) -> new StringStream str
