serialport = require 'serialport'
MessageBus = (require '../common/bus/messagebus').MessageBus

bus = new MessageBus {
	subAddress: 'tcp://raspberrypi:9999',
	pushAddress: 'tcp://raspberrypi:8888',
	subscribe: ["receiver"],
	identity: "mcu-relay"
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

bus.on 'message', (topic, data) ->
	try
		pkg = JSON.parse data
		console.log "Got message: #{JSON.stringify pkg}"
		
		if not pkg.count?
			pkg.count = 1
		
		if pkg.action?
			receiverTogglePower() if pkg.action is "power"
			receiverVolumeUp(pkg.count) if pkg.action is "volumeup"
			receiverVolumeDown(pkg.count) if pkg.action is "volumedown"
		
	catch err
		console.log "Invalid packet: #{err}"

process.on 'SIGINT', () ->
	bus.close()
