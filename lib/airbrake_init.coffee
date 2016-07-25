
exports.initAirbrake = (opts) ->
  checkRequiredFields(opts, isWinstonAirbrake: false)

  airbrake = require('airbrake').createClient(opts.projectId, opts.apiKey)

  airbrake.protocol = opts.protocol || 'https'
  airbrake.servicehost = opts.servicehost || 'api.airbrake.io'
  airbrake.developmentEnvironments = opts.developmentEnvironments if opts.developmentEnvironments
  airbrake.blackListKeys = opts.blackListKeys
  airbrake.whiteListKeys = opts.whiteListKeys
  
  airbrake

exports.initWinstonAirbrake = (opts) ->
  checkRequiredFields(opts, isWinstonAirbrake: true)

  WinstonAirbrake = require('winston-airbrake').Airbrake
  winstonAirbrake = new WinstonAirbrake(opts)

  winstonAirbrake.airbrakeClient.whiteListKeys = opts.whiteListKeys if opts.whiteListKeys
  winstonAirbrake.airbrakeClient.blackListKeys = opts.blackListKeys if opts.blackListKeys

  winstonAirbrake

checkRequiredFields = (opts, isWinstonAirbrake) ->
  unless opts.projectId && isWinstonAirbrake
    throw 'You must specify an airbrake project ID'
  unless opts.apiKey
    throw 'You must specify an airbrake API key'
  unless opts.whiteListKeys
    throw 'You must specify a whitelist'
