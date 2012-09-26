require 'coffee-script'
MessageBus = (require '../common/bus/messagebus').MessageBus

bus = new MessageBus {
	subAddress: 'tcp://raspberrypi:9999',
	pushAddress: 'tcp://raspberrypi:8888',
	subscribe: ["sensor"],
	identity: "triggers"
}

muteEvent = {}
highFridgeTempCounter = 0

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

# Warn if fridge temperature is over 8C for 10 minutes
checkRefrigeratorTemperature = (pkg) ->
	if pkg.location? and pkg.location is "refrigerator"

		if pkg.temperature? and pkg.temperature > 7
			highFridgeTempCounter++
		else
			highFridgeTempCounter = 0

		if highFridgeTempCounter >= 10 and not muteEvent["refrigerator-temp"]
			notify "Refrigerator temperatur high", "Refrigerator temperature is #{pkg.temperature}"
			setMuteEvent "refrigerator-temp", 60*60*1000

bus.on 'message', (topic, pkg) ->
	try
		pkg = JSON.parse pkg

		checkSensorVoltage pkg
		checkRefrigeratorTemperature pkg

	catch error
		console.log error

process.on 'SIGINT', () ->
	bus.close()