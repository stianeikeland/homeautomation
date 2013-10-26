{MessageBus, Sensors} = require 'homeauto'
{Bacon} = require 'baconjs'
socketIO = require 'socket.io'
coffeescript = require 'connect-coffee-script'

express = require 'express'
app = express()

#express.static.mime.define({'text/x-coffeescript': ['coffee']});

bus = new MessageBus {
	subAddress: 'tcp://192.168.0.163:9999'
	pushAddress: 'tcp://192.168.0.163:8888'
}

sensors = new Sensors bus
sensorsLocations = ['livingroom-bookshelf', 'bedroom', 'refrigerator']

cachedData = {}

app.set 'views', __dirname + '/template'
app.set 'view engine', 'jade'
app.engine 'jade', (require 'jade').__express

app.use coffeescript {
	src: __dirname + '/public.src'
	dest: __dirname + '/public'
	bare: true
}

app.use express.static __dirname + '/public'

app.get '/', (req, res) ->
	res.render 'index'

io = socketIO.listen app.listen 8900

cacheAndEmit = (sensorLocation) ->
	Bacon.fromEventTarget(sensors, sensorLocation)
		.slidingWindow(60*60*24, 1)
		.onValue (values) ->
			io.sockets.emit sensorLocation, values
			cachedData[sensorLocation] = values

cacheAndEmit location for location in sensorsLocations

io.sockets.on 'connection', (socket) ->
	console.log "Got connection"
	#socket.emit 'sensors', sensorsLocations
	socket.emit 'initial', cachedData
	#setTimeout (() -> socket.emit 'initial', {bedroom: tmpdata2, "livingroom-bookshelf": lving}), 5000
