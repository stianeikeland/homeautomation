serialport = require 'serialport'
MessageBus = (require '../../common/bus/messagebus').MessageBus

bus = new MessageBus {
	subAddress: 'tcp://raspberrypi:9999',
	pushAddress: 'tcp://raspberrypi:8888',
	subscribe: ["receiver"],
	identity: "mcu-relay-#{process.pid}"
}

locationMapping =
	1: "livingroom-tv",
	2: "refrigerator",
	3: "livingroom-bookshelf",
	4: "bedroom",
	5: "bathroom"

serialOpt =
	baudrate: 57600,
	parser: serialport.parsers.readline("\n")

serial = new serialport.SerialPort "/dev/ttyAMA0", serialOpt

serial.on "data", (data) ->
	console.log "Got: #{data}"
	try
		jdata = JSON.parse data
		jdata.event = "sensor"
		jdata.timestamp = new Date()

		if jdata.nodeid? and locationMapping[jdata.nodeid]?
			jdata.location = locationMapping[jdata.nodeid]
		else
			jdata.location = "unknown"

		bus.send jdata
	catch err
		console.log "Err.. data is not json"

receiverVolumeUp = (count = 1) ->
	serial.write "\nSR,VOLUP\n"
	if count > 1
		setTimeout (() -> receiverVolumeUp --count), 250

receiverVolumeDown = (count = 1) ->
	serial.write "\nSR,VOLDOWN\n"
	if count > 1
		setTimeout (() -> receiverVolumeDown --count), 250

receiverTogglePower = () ->
	serial.write "\nSR,POWER\n"

bus.on 'event', (topic, data) ->
	console.log "Got message: #{JSON.stringify data}"
	data.count = 1 if not pkg.count?

	if data.action?
		receiverTogglePower() if data.action is "power"
		receiverVolumeUp(pkg.count) if data.action is "volumeup"
		receiverVolumeDown(pkg.count) if data.action is "volumedown"


process.on 'SIGINT', () ->
	bus.close()
