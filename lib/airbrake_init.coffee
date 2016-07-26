
exports.initAirbrake = (opts) ->
  checkRequiredFields(opts, isWinstonAirbrake: false)

  airbrake = require('airbrake').createClient(opts.projectId, opts.apiKey)

  airbrake.env = opts.env if opts.env
  airbrake.protocol = opts.protocol if opts.protocol
  airbrake.servicehost = opts.host if opts.host
  airbrake.developmentEnvironments = opts.developmentEnvironments if opts.developmentEnvironments
  airbrake.blackListKeys = opts.blackListKeys if opts.blackListKeys
  airbrake.whiteListKeys = opts.whiteListKeys if opts.whiteListKeys
  airbrake.ignoredExceptions = opts.ignoredExceptions if opts.ignoredExceptions

  airbrake

exports.initWinstonAirbrake = (opts) ->
  checkRequiredFields(opts, isWinstonAirbrake: true)

  WinstonAirbrake = require('winston-airbrake').Airbrake
  winstonAirbrake = new WinstonAirbrake(opts)

  winstonAirbrake.airbrakeClient.whiteListKeys = opts.whiteListKeys if opts.whiteListKeys
  winstonAirbrake.airbrakeClient.blackListKeys = opts.blackListKeys if opts.blackListKeys
  winstonAirbrake.airbrakeClient.ignoredExceptions = opts.ignoredExceptions if opts.ignoredExceptions

  winstonAirbrake

checkRequiredFields = (opts, {isWinstonAirbrake}) ->
  unless opts.apiKey
    throw 'You must specify an airbrake API key'
  unless opts.whiteListKeys
    throw 'You must specify a whitelist'
  unless (isWinstonAirbrake || opts.projectId)
    throw 'You must specify an airbrake project ID'
