{MessageBus, Sensors, BusEvents} = require 'homeauto'
{Bacon} = require 'baconjs'
socketIO = require 'socket.io'
coffeescript = require 'connect-coffee-script'

CACHEWINDOW = 1000*60*60*24 # Cache sensor data for 24 hours

authentication =
	user: process.env.WEBUIUSER || "username"
	pass: process.env.WEBUIPASS || "password"

express = require 'express'
app = express()

bus = new MessageBus

sensors = new Sensors bus
sensorsLocations = ['livingroom-bookshelf', 'bedroom', 'refrigerator', 'outside']

termostat = new BusEvents bus, "termostat", ["type"]

cachedData = {}

app.set 'views', __dirname + '/template'
app.set 'view engine', 'jade'
app.engine 'jade', (require 'jade').__express

app.use coffeescript {
	src: __dirname + '/public.src'
	dest: __dirname + '/public'
	bare: true
}

app.use express.basicAuth (user, pass) ->
	user is authentication.user and pass is authentication.pass

app.use express.static __dirname + '/public'
app.use '/bower_components', express.static __dirname + '/bower_components'

app.get '/', (req, res) ->
	res.render 'index'

io = socketIO.listen app.listen 8900

# Sliding window containing cachewindow ms sensor data.
timeWindow = (window, val) ->
	now = new Date
	(window.filter (x) -> now - new Date(x.timestamp) < CACHEWINDOW).concat [val]

setUpSensorStream = (sensorLocation) ->
	stream = Bacon.fromEventTarget(sensors, sensorLocation)
	# Emit new value to listening clients
	stream.onValue (val) -> io.sockets.emit sensorLocation, val
	# Cache 24 hours of sensor data (given to clients on first connect)
	stream.scan([], timeWindow).onValue (values) -> cachedData[sensorLocation] = values

setUpSensorStream location for location in sensorsLocations

setUpTermostatStream = () ->
	stream = (Bacon.fromEventTarget termostat, "target")
		.map (data) ->
			data.location = "termostat"
			return data
	stream.onValue (val) -> io.sockets.emit "termostat", val
	stream.scan([], timeWindow).onValue (values) -> cachedData["termostat"] = values

setUpTermostatStream()

io.sockets.on 'connection', (socket) ->
	console.log "Got connection"
	socket.emit 'initial', cachedData

	socket.on 'bus', (msg) ->
		bus.send msg
