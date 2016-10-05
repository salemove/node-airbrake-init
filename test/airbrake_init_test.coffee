expect = (require 'chai').expect
xpath = require('xpath')
dom = require('xmldom').DOMParser
AirbrakeInit = require('../lib/airbrake_init')
sinon = require('sinon')
assert = require('assert')
memo = require('memo-is')

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
      expect(airbrake.projectId).to.eql('123')
      expect(airbrake.key).to.eql('myAirbrakeId')
      expect(airbrake.whiteListKeys).to.eql(['FOO'])
      expect(airbrake.blackListKeys).to.eql(['BAR'])
      expect(airbrake.ignoredExceptions).to.eql(['plzignore'])
      expect(airbrake.env).to.eql('prod')

    it 'requires project ID', ->
      expect(() -> createAirbrakeWithoutConfigEntry('projectId'))
      .to.throw("You must specify an Airbrake project ID ('projectId')")

    it 'requires API key', ->
      expect(() -> createAirbrakeWithoutConfigEntry('apiKey'))
      .to.throw("You must specify an Airbrake API key ('apiKey')")

    it 'requires whitelist', ->
      expect(() -> createAirbrakeWithoutConfigEntry('whiteListKeys'))
      .to.throw("You must specify a whitelist ('whiteListKeys')")

    describe 'filters', ->
      airbrake = null
      environment = memo().is -> null

      beforeEach ->
        configKeys =
          'projectId': '123'
          'apiKey': 'myAirbrakeId'
          'whiteListKeys': ['keys']
          'developmentEnvironments': ['dev', 'staging']
          'env': environment()
        airbrake = AirbrakeInit.initAirbrake(configKeys)

      it 'has a filter', ->
        expect(airbrake.filters).to.have.length(1)

      describe 'environment filter', ->
        filter = null

        errorNotice = (errorMessage) ->
          airbrake.notifyJSON(new Error(errorMessage))

        beforeEach ->
          filter = airbrake.filters[0]

        context 'in development environment', ->
          environment.is -> 'dev'

          it 'returns null', ->
            notice = errorNotice('an error')
            expect(filter(notice)).to.be.null

        context 'in production environment', ->
          environment.is -> 'prod'

          it 'returns notice with same context', ->
            notice = errorNotice('an error')
            filteredNotice = filter(notice)
            expect(filteredNotice).not.to.be.null
            expect(filteredNotice.context).to.eql(notice.context)

    describe 'whitelist', ->
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

    buildNoticeEnvironmentJSON = (airbrake) ->
      airbrake.environmentJSON(new Error('error'))

    createAirbrakeWithConfigEntry = (key, value) ->
      AirbrakeInit.initAirbrake(withEntry(exampleKeys, key, value))

    createAirbrakeWithoutConfigEntry = (key) ->
      AirbrakeInit.initAirbrake(withoutEntry(exampleKeys, key))


  describe 'winston-airbrake', ->

    it 'has configuration', ->
      airbrake = AirbrakeInit.initWinstonAirbrake(exampleKeys).airbrakeClient
      expect(airbrake.key).to.eql('myAirbrakeId')
      expect(airbrake.whiteListKeys).to.eql(['FOO'])
      expect(airbrake.blackListKeys).to.eql(['BAR'])
      expect(airbrake.ignoredExceptions).to.eql(['plzignore'])
      expect(airbrake.env).to.eql('prod')

    it 'requires API key', ->
      expect(() -> createAirbrakeWithoutConfigEntry('apiKey'))
        .to.throw("You must specify an Airbrake API key ('apiKey')")

    it 'requires whitelist', ->
      expect(() -> createAirbrakeWithoutConfigEntry('whiteListKeys'))
        .to.throw("You must specify a whitelist ('whiteListKeys')")

    it 'defaults env to development', ->
      expect(createAirbrakeWithoutConfigEntry('env').env).to.eql('development')

    describe 'with NODE_ENV set', ->
      beforeEach ->
        @node_env = process.env.NODE_ENV
        process.env.NODE_ENV = 'foo'

      afterEach ->
        process.env.NODE_ENV = @node_env

      it 'defaults env to NODE_ENV', ->
        expect(createAirbrakeWithoutConfigEntry('env').env).to.eql('foo')

    describe 'whitelist', ->

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

    buildNoticeXmlDom = (airbrakeClient) ->
      new dom().parseFromString(airbrakeClient.notifyXml(new Error('error')).toString())

    extractEnvironmentVariableFromNotice = (noticeXmlDom, key) ->
      xpath.select("//request/cgi-data/var[@key='#{key}']/text()", noticeXmlDom)[0].toString()

    createAirbrakeWithConfigEntry = (key, value) ->
      AirbrakeInit.initWinstonAirbrake(withEntry(exampleKeys, key, value)).airbrakeClient

    createAirbrakeWithoutConfigEntry = (key) ->
      AirbrakeInit.initWinstonAirbrake(withoutEntry(exampleKeys, key)).airbrakeClient
