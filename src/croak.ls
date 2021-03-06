require! {
  grunt
  _: lodash
  './config'
  './croakfile'
  '../package.json'.version
}

module.exports =

  version: version
  grunt-version: grunt.version

  config: config
  grunt: grunt

  load: -> it |> config.load

  get: -> it |> config.get

  set: -> it |> config.set

  load-default: ->
    it |> @load unless config.has-data!
    config.get-default-project!

  init: (options, project) ->
    # extends options with project config
    options := (options |> _.extend {}, project, _) |> map-options
    # init grunt with project options
    options |> @init-grunt

  run: -> @init ...

  init-grunt: (options = {}) ->
    # omit unsupported grunt options
    options := options |> omit-options
    # load Croakfile, if exist
    croakfile-dir = options |> croakfile.load _, (options.$dirname or options.cwd)
    # expose croak paths as grunt config object
    croak-config-object = options |> grunt-croak-object
    # make croak available in grunt
    grunt.croak = { options.base, options.tasks, options.npm } |> _.defaults croak-config-object, _
    # wrap grunt.initConfig method
    grunt.init-config = croak-config-object |> init-config
    # remove croak first argument
    grunt.cli.tasks.splice 0, 1 if grunt.cli.tasks
    # force to override process.argv, it was taken
    # by the Grunt module instance and it has precedence
    # todo: use grunt.option() instead
    options |> _.extend grunt.cli.options, _
    # init grunt with inherited options
    options |> grunt.cli


# expose Croak paths as Grunt config
# and make it available for templating
grunt-croak-object = (options) ->
  cwd = process.cwd!

  cwd: cwd
  root: croakfile.dirname or config.dirname!local or cwd
  config: config.dirname!local
  base: options.base or cwd
  croakfile: croakfile.dirname or null
  gruntfile: options.gruntfile or null
  npm: options.npm
  tasks: options.tasks
  options: options
  version: version

set-grunt-croak-config = (config) ->
  # add specific options avaliable from config
  config |> grunt.config.set 'croak', _ unless 'croak' |> grunt.config.get

init-config = (croak-config-object) ->
  { init-config } = grunt

  (config) ->
    config |> init-config
    croak-config-object |> set-grunt-croak-config

omit-options = ->
  options = {}

  # supported grunt options
  grunt-args = <[
    no-color
    base
    gruntfile
    debug
    stack
    force
    tasks
    npm
    no-write
    verbose
  ]>

  for own key, value of it
    when value? and value isnt false and (key |> grunt-args.index-of) isnt -1
    then options <<< (key): value

  options

map-options = ->
  map = 'package': 'gruntfile'

  for own origin, target of map
    when (origin := it[origin])? and not it[target]?
    then it <<< (target): origin
  it
