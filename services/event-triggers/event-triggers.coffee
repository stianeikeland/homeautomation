MessageBus = (require 'homeauto').MessageBus
Sensors    = (require 'homeauto').Sensors
Power      = (require 'homeauto').PowerEvents

bus = new MessageBus {
	subscribe: ["sensor", "power"],
	identity: "triggers-#{process.pid}"
}

sensors = new Sensors bus
power = new Power bus

process.on 'SIGINT', () ->
	bus.close()

muteEvent = {}

timers = {}

setMuteEvent = (event, timeout = 24*60*60*1000) ->
	muteEvent[event] = true
	unMute = () ->
		muteEvent[event] = false
	setTimeout unMute, timeout

notify = (subject, content, action = 'prowl') ->
	data =
		event: "notification",
		subject: subject,
		content: content,
		action: action

	bus.send data
	console.log "Sending notification >> #{JSON.stringify data}"

# Warn if any sensors drop below 3.10v
checkSensorVoltage = (pkg) ->
	if pkg.voltage? and pkg.voltage <= 3100 and not muteEvent["#{pkg.nodeid}-voltage"]
		setMuteEvent "#{pkg.nodeid}-voltage"
		notify "Sensor voltage low - #{pkg.location}", "Voltage on sensor '#{pkg.location}' is #{pkg.voltage} < 3.10 volt"

sensors.on 'all', checkSensorVoltage

# Check if a given value on a given sensor is within a valid range.
# No new checks/notifcations for wrapuptime.
sensorBoundsTrigger = (sensor, property, lowerbound, upperbound, countlimit = 1, wrapuptime = 60*60*1000) ->
	setTrigger = (count = 0) ->
		sensors.once sensor, (data) ->
			outsideBounds = (data[property] < lowerbound or data[property] > upperbound)
			if count >= countlimit and outsideBounds
				notify "#{sensor} #{property} is #{data[property]}", "#{sensor} #{property} outside valid range (#{lowerbound} - #{upperbound})"
				setTimeout setTrigger, wrapuptime
			else if outsideBounds
				setTrigger count + 1
			else
				setTrigger()
	setTrigger()

# Report if a given sensor is missing for a given interval
checkIfMissing = (sensor, timeout = 10*60*1000, wrapuptime = 60*60*1000) ->
	setTrigger = () ->
		sensorMissing = () ->
			notify "Sensor #{sensor} missing!", "Sensor #{sensor} has not reported in for #{timeout / (1000*60)} minutes."
			setTimeout setTrigger, wrapuptime

		timer = setTimeout sensorMissing, timeout

		sensors.once sensor, (data) ->
			clearTimeout timer
			setTrigger()

	setTrigger()

# safety timer for things like coffee-maker and water heater
safetyTimer = (event, delay) ->
	powerDown = () ->
		bus.send {
			event: "power",
			type: "command",
			command: "off",
			location: event.location
		}
		delete timers[event.location]
		console.log "Safety timer for #{event.location} triggered."

	if event.command? and event.command is "on"
		console.log "Setting safety timer trigger for #{event.location}."
		clearTimeout timers[event.location] if timers[event.location]?
		timers[event.location] = setTimeout powerDown, delay


# TRIGGER HELPERS #

sensorlist = ['refrigerator', 'livingroom-bookshelf', 'bedroom']
minute = 60 * 1000
hour = 60 * minute
day = 24 * hour

# TRIGGER CONDITIONS #

#sensorBoundsTrigger = (sensor, property, lowerbound, upperbound, countlimit = 1, wrapuptime = 60*60*1000)
# Notify if temperature in the refrigerator is outside -2..7 for 10 minutes.
sensorBoundsTrigger 'refrigerator', 'temperature', -2, 7, 10, hour
# Notify if temperature in livingroom is outside 5..30 for 10 minutes
sensorBoundsTrigger 'livingroom-bookshelf', 'temperature', 5, 30, 10, hour

# Notify if sensors are not reporting in within 10 minutes, wait 5 hours for next notification
checkIfMissing sensor, 30 * minute, 5 * hour for sensor in sensorlist

# Safetytimer, turn off after x minutes:
power.on 'kitchen-coffee', (event) -> safetyTimer event, 60 * minute
power.on 'kitchen-water', (event) -> safetyTimer event, 10 * minute
