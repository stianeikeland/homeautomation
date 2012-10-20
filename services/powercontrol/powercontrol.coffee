require 'coffee-script'
rfxcom = require 'rfxcom'

units = require './powerconfig.json'

MessageBus = (require '../../common/bus/messagebus').MessageBus

bus = new MessageBus {
	subscribe: ["power"],
	identity: "rfxcom-#{process.pid}"
}

rfx = new rfxcom.RfxCom "/dev/ttyUSB0", {debug:true}
lighting2 = new rfxcom.Lighting2 rfx, rfxcom.lighting2.AC

rfx.initialise () ->
	console.log "RfxCom connected.."

handleTriggers = (event) ->
	return if not units.triggerconfig? or not units.triggerconfig[event.location]?
	return if not units.triggerconfig[event.location][event.command]?

	for action in units.triggerconfig[event.location][event.command]
		if not action.event?
			action.event = "power"
			action.type = "command"	
		bus.send action

handleSwitchEvent = (event) ->
	event.code = event.id
	event.id = "#{event.id}/#{event.unitcode}"
	event.command = event.command.toLowerCase() if event.command?

	# Is this a known switch?
	if units.switches?[event.id]?
		event.event = "power"
		event.type = "switch"
		event.location = units.switches[event.id]
		bus.send event
		handleTriggers event

	console.log event

handleBusOrders = (topic, event) ->
	if event.type? and event.type is "command" and event.command?

		if event.location? and units.receivers[event.location]?
			event.id = units.receivers[event.location]

		if event.id?
			lighting2.switchOn event.id if event.command.toLowerCase() is "on"
			lighting2.switchOff event.id if event.command.toLowerCase() is "off"
			console.log event

rfx.on 'lighting1', handleSwitchEvent
rfx.on 'lighting2', handleSwitchEvent
bus.on "event", handleBusOrders
