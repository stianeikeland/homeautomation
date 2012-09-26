serialport = require 'serialport'
zmq = require 'zmq'

brokerSubAddr = 'tcp://127.0.0.1:9999'
brokerPushAddr = 'tcp://127.0.0.1:8888'
brokerSub = zmq.socket 'sub'
brokerPush = zmq.socket 'push'

brokerPush.identity = 'relaypush' + process.pid
brokerSub.identity = 'relaysub' + process.pid

locationMapping =
	1: "livingroom-tv",
	2: "refrigerator",
	3: "livingroom-bookshelf",
	4: "bedroom",
	5: "bathroom"

serialOpt =
	baudrate: 57600,
	parser: serialport.parsers.readline("\n")

brokerSub.connect brokerSubAddr, (err) ->
	throw err if err
	console.log 'Sub Broker connected!'

brokerPush.connect brokerPushAddr, (err) ->
	throw err if err
	console.log 'Push Broker connected!'

brokerSub.subscribe 'receiver'

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

		brokerPush.send JSON.stringify jdata
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

brokerSub.on 'message', (topic, data) ->
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
	brokerSub.close()
	brokerPush.close()