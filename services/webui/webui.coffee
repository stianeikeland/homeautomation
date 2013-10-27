{MessageBus, Sensors} = require 'homeauto'
{Bacon} = require 'baconjs'
socketIO = require 'socket.io'
coffeescript = require 'connect-coffee-script'

express = require 'express'
app = express()

bus = new MessageBus

sensors = new Sensors bus
sensorsLocations = ['livingroom-bookshelf', 'bedroom', 'refrigerator', 'outside']

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
app.use '/bower_components', express.static __dirname + '/bower_components'

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
	socket.emit 'initial', cachedData
