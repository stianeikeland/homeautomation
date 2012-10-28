events = require 'events'

class Sensors extends events.EventEmitter

	constructor: (@messagebus, options = {}) ->

		options.maxlisteners = 50 if not options.maxlisteners?
		@setMaxListeners options.maxlisteners

		@messagebus.subscribe 'sensor'
		@messagebus.on 'event', @handleEvent

	handleEvent: (topic, event) =>
		if topic.toString() is 'sensor'
			@emit event.nodeid, event if event.nodeid?
			@emit event.location, event if event.location?
			@emit 'all', event

exports.Sensors = Sensors