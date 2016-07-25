chai = require 'chai'
expect = chai.expect
AirbrakeInit = require('../lib/airbrake_init')

describe 'airbrake_init', ->

  withEntry = (hash, key, value) ->
    hashClone = clone(hash)
    hashClone[key] = value
    hashClone

  withoutEntry = (hash, key) ->
    hashClone = clone(hash)
    delete hashClone[key]
    hashClone

  clone = (hash) ->
    JSON.parse(JSON.stringify(hash))

  exampleKeys = 
    'projectId': 'id'
    'apiKey': 'key'
    'whiteListKeys': ['FOO']

  describe 'vanilla airbrake', ->

    it 'has project ID', ->
      airbrake = AirbrakeInit.initAirbrake(withEntry(exampleKeys, 'projectId', 'id'))
      airbrake.projectId.should.eql('id')

    it 'has API key', ->
      airbrake = AirbrakeInit.initAirbrake(withEntry(exampleKeys, 'apiKey', 'key'))
      airbrake.key.should.eql('key')

    it 'has whitelist', ->
      airbrake = AirbrakeInit.initAirbrake(withEntry(exampleKeys, 'whiteListKeys', ['FOO']))
      airbrake.whiteListKeys.should.eql(['FOO'])

    it 'requires project ID', ->
      expect(() -> AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, 'projectId'))).to.throw('You must specify an airbrake project ID')

    it 'requires API key', ->
      expect(() -> AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, 'apiKey'))).to.throw('You must specify an airbrake API key')

    it 'requires whitelist', ->
      expect(() -> AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, 'whiteListKeys'))).to.throw('You must specify a whitelist')

  describe 'winston-airbrake', ->

    it 'has API key', ->
      winstonAirbrake = AirbrakeInit.initWinstonAirbrake(withEntry(exampleKeys, 'apiKey', 'id'))
      winstonAirbrake.airbrakeClient.key.should.eql('id')
    