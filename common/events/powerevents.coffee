events = require 'events'

class PowerEvents extends events.EventEmitter

	constructor: (@messagebus, options = {}) ->

		options.maxlisteners = 50 if not options.maxlisteners?
		@setMaxListeners options.maxlisteners

		@messagebus.subscribe 'power'
		@messagebus.on 'event', @handleEvent

	handleEvent: (topic, event) =>
		if topic.toString() is 'power'
			@emit event.type, event if event.type?
			@emit event.location, event if event.location?
			@emit event.command, event if event.command?
			@emit 'all', event

	send: (event) =>
		event.event = "power"
		event.type = "command"
		@messagebus.send event

exports.PowerEvents = PowerEvents