Node AirbrakeInit
==================

Helps to instantiate node-airbrake and winston-airbrake

[![Build Status](https://travis-ci.org/salemove/node-airbrake-init.svg?branch=master)](https://travis-ci.org/salemove/node-airbrake-init)


## Installation

Using npm form the command line
```
$ npm install --save airbrake-init
```

## Usage
```js
  var options = { 'projectId': '123', 'apiKey': 'key', 'whiteListKeys': ['FOO'] };
  var airbrake = require('airbrake-init').initAirbrake(options);
```

```js
  var options = { 'apiKey': 'key', 'whiteListKeys': ['FOO'] };
  var winstonAirbrake = require('airbrake-init').initWinstonAirbrake(options);
```
