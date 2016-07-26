chai = require 'chai'
expect = chai.expect
xpath = require('xpath')
dom = require('xmldom').DOMParser
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
    'projectId': '123'
    'apiKey': 'myAirbrakeId'
    'whiteListKeys': ['FOO']
    'blackListKeys': ['BAR']
    'ignoredExceptions': ['plzignore']
    'env': 'prod'

  filtered = '[FILTERED]'

  describe 'vanilla airbrake', ->

    it 'has configuration', ->
      airbrake = AirbrakeInit.initAirbrake(exampleKeys)
      airbrake.projectId.should.eql('123')
      airbrake.key.should.eql('myAirbrakeId')
      airbrake.whiteListKeys.should.eql(['FOO'])
      airbrake.blackListKeys.should.eql(['BAR'])
      airbrake.ignoredExceptions.should.eql(['plzignore'])
      airbrake.env.should.eql('prod')

    it 'requires project ID', ->
      expect(() -> AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, 'projectId')))
      .to.throw('You must specify an airbrake project ID')

    it 'requires API key', ->
      expect(() -> AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, 'apiKey')))
      .to.throw('You must specify an airbrake API key')

    it 'requires whitelist', ->
      expect(() -> AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, 'whiteListKeys')))
      .to.throw('You must specify a whitelist')

    describe 'whitelist', ->

      beforeEach ->
        process.env.MY_VAR = 'sweet home'
        process.env.SECRET_STUFF = 'my secrets'
        airbrake = AirbrakeInit.initAirbrake(withEntry(exampleKeys, 'whiteListKeys', ['MY_VAR']))
        @noticeEnvironmentJson = airbrake.environmentJSON(new Error('error'))

      afterEach ->
        delete process.env.MY_VAR
        delete process.env.SOME_SECRET_STUFF

      it 'allows parameters in list', ->
        @noticeEnvironmentJson['MY_VAR'].should.eql('sweet home')

      it 'filters parameters not in list', ->
        @noticeEnvironmentJson['SECRET_STUFF'].should.eql(filtered)


  describe 'winston-airbrake', ->

    it 'has configuration', ->
      airbrake = AirbrakeInit.initWinstonAirbrake(exampleKeys).airbrakeClient
      airbrake.key.should.eql('myAirbrakeId')
      airbrake.whiteListKeys.should.eql(['FOO'])
      airbrake.blackListKeys.should.eql(['BAR'])
      airbrake.ignoredExceptions.should.eql(['plzignore'])
      airbrake.env.should.eql('prod')

    it 'requires API key', ->
      expect(() -> AirbrakeInit.initWinstonAirbrake(withoutEntry(exampleKeys, 'apiKey')))
        .to.throw('You must specify an airbrake API key')

    it 'requires whitelist', ->
      expect(() -> AirbrakeInit.initWinstonAirbrake(withoutEntry(exampleKeys, 'whiteListKeys')))
      .to.throw('You must specify a whitelist') 

    describe 'whitelist', ->

      beforeEach ->
        process.env.MY_VAR = 'o hi'
        process.env.SECRET_STUFF = 'password'
        winstonAirbrake = AirbrakeInit.initWinstonAirbrake(withEntry(exampleKeys, 'whiteListKeys', ['MY_VAR']))
        xml = winstonAirbrake.airbrakeClient.notifyXml(new Error('error'), true).toString()
        @noticeXmlDom = new dom().parseFromString(xml)

      afterEach ->
        delete process.env.MY_VAR
        delete process.env.SOME_SECRET_STUFF

      it 'allows parameters in list', ->
        home = xpath.select("//request/cgi-data/var[@key='MY_VAR']/text()", @noticeXmlDom)[0].toString()
        expect(home).to.eql('o hi')

      it 'filters parameters not in list', ->
        secret = xpath.select("//request/cgi-data/var[@key='SECRET_STUFF']/text()", @noticeXmlDom)[0].toString()
        expect(secret).to.eql(filtered)
