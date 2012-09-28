require 'coffee-script'
MessageBus = (require '../../common/bus/messagebus').MessageBus
Sensors = (require '../../common/events/sensors').Sensors

bus = new MessageBus {
	subAddress: 'tcp://raspberrypi:9999',
	pushAddress: 'tcp://raspberrypi:8888',
	subscribe: ["sensor"],
	identity: "triggers-#{process.pid}"
}

sensors = new Sensors bus

process.on 'SIGINT', () ->
	bus.close()

muteEvent = {}

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
	if pkg.voltage? and pkg.voltage < 310 and not muteEvent["#{pkg.nodeid}-voltage"]
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
				notify "#{sensor} #{property} outside valid range", "#{sensor} #{property} is #{data[property]}"
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


# TRIGGER HELPERS #

sensorlist = ['refrigerator', 'livingroom-bookshelf']
minute = 60 * 1000
hour = 60 * minute
day = 24 * hour

# TRIGGER CONDITIONS #

# Notify if temperature in the refrigerator is outside -5..7 for 10 minutes.
sensorBoundsTrigger 'refrigerator', 'temperature', 10, -5, 7, hour
# Notify if temperature in livingroom is outside 5..30 for 5 minutes
sensorBoundsTrigger 'livingroom-bookshelf', 'temperature', 5, 5, 30, hour

# Notify if sensors are not reporting in within 5 minutes, wait 5 hours for next notification
checkIfMissing sensor, 5 * minute, 5 * hour for sensor in sensorlist
