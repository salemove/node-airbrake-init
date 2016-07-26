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

    createAirbrakeWithConfigEntry = (key, value) ->
      AirbrakeInit.initAirbrake(withEntry(exampleKeys, key, value))

    createAirbrakeWithoutConfigEntry = (key) ->
      AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, key))

    it 'has configuration', ->
      airbrake = AirbrakeInit.initAirbrake(exampleKeys)
      airbrake.projectId.should.eql('123')
      airbrake.key.should.eql('myAirbrakeId')
      airbrake.whiteListKeys.should.eql(['FOO'])
      airbrake.blackListKeys.should.eql(['BAR'])
      airbrake.ignoredExceptions.should.eql(['plzignore'])
      airbrake.env.should.eql('prod')

    it 'requires project ID', ->
      expect(() -> createAirbrakeWithoutConfigEntry('projectId'))
      .to.throw("You must specify an Airbrake project ID ('projectId')")

    it 'requires API key', ->
      expect(() -> createAirbrakeWithoutConfigEntry('apiKey'))
      .to.throw("You must specify an Airbrake API key ('apiKey')")

    it 'requires whitelist', ->
      expect(() -> createAirbrakeWithoutConfigEntry('whiteListKeys'))
      .to.throw("You must specify a whitelist ('whiteListKeys')")

    describe 'whitelist', ->

      buildNoticeEnvironmentJSON = (airbrake) ->
        airbrake.environmentJSON(new Error('error'))

      beforeEach ->
        process.env.MY_VAR = 'sweet home'
        process.env.SECRET_STUFF = 'my secrets'

      afterEach ->
        delete process.env.MY_VAR
        delete process.env.SECRET_STUFF

      it 'allows parameters in list', ->
        noticeJSON = buildNoticeEnvironmentJSON(createAirbrakeWithConfigEntry('whiteListKeys', ['MY_VAR']))
        noticeJSON['MY_VAR'].should.eql('sweet home')

      it 'filters parameters not in list', ->
        noticeJSON = buildNoticeEnvironmentJSON(createAirbrakeWithConfigEntry('whiteListKeys', ['MY_OTHER_VAR']))
        noticeJSON['SECRET_STUFF'].should.eql(filtered)


  describe 'winston-airbrake', ->

    createAirbrakeWithConfigEntry = (key, value) ->
      AirbrakeInit.initWinstonAirbrake(withEntry(exampleKeys, key, value)).airbrakeClient

    createAirbrakeWithoutConfigEntry = (key) ->
      AirbrakeInit.initWinstonAirbrake(withoutEntry(exampleKeys, key))

    it 'has configuration', ->
      airbrake = AirbrakeInit.initWinstonAirbrake(exampleKeys).airbrakeClient
      airbrake.key.should.eql('myAirbrakeId')
      airbrake.whiteListKeys.should.eql(['FOO'])
      airbrake.blackListKeys.should.eql(['BAR'])
      airbrake.ignoredExceptions.should.eql(['plzignore'])
      airbrake.env.should.eql('prod')

    it 'requires API key', ->
      expect(() -> createAirbrakeWithoutConfigEntry('apiKey'))
        .to.throw("You must specify an Airbrake API key ('apiKey')")

    it 'requires whitelist', ->
      expect(() -> createAirbrakeWithoutConfigEntry('whiteListKeys'))
      .to.throw("You must specify a whitelist ('whiteListKeys')")

    describe 'whitelist', ->

      buildNoticeXmlDom = (airbrakeClient) ->
        new dom().parseFromString(airbrakeClient.notifyXml(new Error('error')).toString())

      extractEnvironmentVariableFromNotice = (noticeXmlDom, key) ->
        xpath.select("//request/cgi-data/var[@key='#{key}']/text()", noticeXmlDom)[0].toString()

      beforeEach ->
        process.env.MY_VAR = 'o hi'
        process.env.SECRET_STUFF = 'password'

      afterEach ->
        delete process.env.MY_VAR
        delete process.env.SECRET_STUFF

      it 'allows parameters in list', ->
        noticeXmlDom = buildNoticeXmlDom(createAirbrakeWithConfigEntry('whiteListKeys', ['MY_VAR']))
        extractEnvironmentVariableFromNotice(noticeXmlDom, 'MY_VAR').should.eql('o hi')

      it 'filters parameters not in list', ->
        noticeXmlDom = buildNoticeXmlDom(createAirbrakeWithConfigEntry('whiteListKeys', ['TOTALLY_NOT_SECRET']))
        extractEnvironmentVariableFromNotice(noticeXmlDom, 'SECRET_STUFF').should.eql(filtered)
