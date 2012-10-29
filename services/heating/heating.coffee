# A simple termostat implementation
# Todo: PID control, and movement (PIR)

require 'datejs'

MessageBus   = (require 'homeauto').MessageBus
PowerEvents  = (require 'homeauto').PowerEvents
Sensors      = (require 'homeauto').Sensors

bus     = new MessageBus { identity: "heating-#{process.pid}" }
sensors = new Sensors bus
power   = new PowerEvents bus

sensorlocation  = "livingroom-bookshelf"
heaterlocation  = "livingroom-heating"
lastTemperature = false
tempTimer       = false

# Temperature targets for home / away
temperatureHome = 23
temperatureAway = 17

# Temporary, untill I get movement sensors in place..

timeRulesWeekdays = [
	["0:00", temperatureAway], # must be here..
	["6:00", temperatureHome],
	["8:00", temperatureAway], # TODO: if movement
	["15:30", temperatureHome],
	["17:00", temperatureHome], # TODO: if movement
	["22:00", temperatureAway]
]

timeRulesWeekend = [
	["0:00", temperatureAway], # must be here..
	["7:30", temperatureHome],
	["10:00", temperatureHome] # TODO: if movement
]


getTargetTemperature = () ->
	now = new Date
	table = if now.getDay() < 1 or now.getDay() > 5 then timeRulesWeekend else timeRulesWeekdays

	i = table.length
	while --i >= 0
		current = Date.parse table[i][0]
		return table[i][1] if (now >= current)

	return table[0][1]


controlHeating = () ->
	command = { location: heaterlocation, command: "off" }

	if not lastTemperature
		power.send command
		return

	if lastTemperature.temperature? and lastTemperature.temperature < getTargetTemperature()
		command.command = "on"
	power.send command


sensors.on sensorlocation, (event) ->
	lastTemperature = event
	clearTimeout tempTimer if tempTimer

	# Clear known temperature if older than 5 minutes
	clearOldTemp = () ->
		lastTemperature = false
	tempTimer = setTimeout clearOldTemp, 5*60*1000

# Set heating on / off every 5 minutes
setInterval controlHeating, 5*60*1000

console.log "Heating service running.."
