zmq = require 'zmq'
nconf = require 'nconf'
_ = require 'underscore'

class MessageBus

	constructor: (useroptions = {}) ->

		nconf.overrides useroptions
		nconf.env()
		nconf.file 'busconfig.json'
		nconf.defaults {
			identity: "#{process.pid}",
			subAddress: 'tcp://127.0.0.1:9999',
			pushAddress: 'tcp://127.0.0.1:8888'
		}

		@sub = zmq.socket 'sub'
		@push = zmq.socket 'push'

		@sub.identity = nconf.get 'identity'
		@push.identity = nconf.get 'identity'

		@sub.connect nconf.get 'subAddress'
		@push.connect nconf.get 'pushAddress'

		if useroptions.subscribe?
			@subscribe useroptions.subscribe

	send: (data, callback) ->
		try
			data.timestamp = new Date()
			@push.send JSON.stringify data
		catch error
			callback error

	subscribe: (topics = []) ->
		if _.isString topic
			topics = [topics]

		@sub.subscribe topic for topic in topics

	on: (event, callback) ->
		@sub.on event, callback

	close: () ->
		@sub.close()
		@push.close()

exports.MessageBus = MessageBus