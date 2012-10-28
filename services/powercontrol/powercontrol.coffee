rfxcom     = require 'rfxcom'
MessageBus = (require 'homeauto').MessageBus
PowerEvents      = (require 'homeauto').PowerEvents

units      = require './powerconfig.json'

bus = new MessageBus { identity: "rfxcom-#{process.pid}" }
powerevents = new PowerEvents bus

rfx = new rfxcom.RfxCom "/dev/ttyUSB0", {debug:true}
lighting2 = new rfxcom.Lighting2 rfx, rfxcom.lighting2.AC

rfx.initialise () ->
	console.log "RfxCom connected.."

handleTriggers = (event) ->
	return if not units.triggerconfig? or not units.triggerconfig[event.location]?
	return if not units.triggerconfig[event.location][event.command]?

	for action in units.triggerconfig[event.location][event.command]
		powerevents.send action

handleSwitchEvent = (event) ->
	event.code = event.id
	event.id = "#{event.id}/#{event.unitcode}"
	event.command = event.command.toLowerCase() if event.command?

	# Is this a known switch?
	if units.switches?[event.id]?
		event.type = 'switch'
		event.location = units.switches[event.id]
		powerevents.send event
		handleTriggers event

	console.log event

handleBusOrders = (event) ->
	if event.command?
		if event.location? and units.receivers[event.location]?
			event.id = units.receivers[event.location]

		if event.id?
			lighting2.switchOn event.id if event.command.toLowerCase() is 'on'
			lighting2.switchOff event.id if event.command.toLowerCase() is 'off'

	console.log event

rfx.on 'lighting1', handleSwitchEvent
rfx.on 'lighting2', handleSwitchEvent
powerevents.on 'command', handleBusOrders
