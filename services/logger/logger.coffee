# Logger service for home automation
# Pushes sensor data to cosm every 30 seconds

require 'coffee-script'

request    = require 'request'
nconf      = require 'nconf'
MessageBus = (require '../../common/bus/messagebus').MessageBus
Sensors    = (require '../../common/events/sensors').Sensors

nconf.argv().env().file {file: 'cosmconfig.json'}

throw "Missing feed id" if not nconf.get 'feedid'
throw "Missing api key" if not nconf.get 'apikey'

bus = new MessageBus {
	subscribe: ["sensors"],
	identity: "logger-#{process.pid}"
}
sensors = new Sensors bus

cosmRequestTemplate =
	url: "http://api.cosm.com/v2/feeds/#{nconf.get 'feedid'}"
	method: "PUT"
	headers:
		"X-ApiKey": nconf.get 'apikey'
	json:
		version: "1.0.0"
		datastreams: []

logQueue = {}

pushToCosm = () ->
	data = []
	data.push {id: key, current_value: logQueue[key]} for key of logQueue

	logQueue = {}

	console.dir data
	return if data.length == 0

	cosmRequest = cosmRequestTemplate
	cosmRequest.json.datastreams = data
	request cosmRequest

# Push data to cosm every 30 sec
setInterval pushToCosm, 30000

sensors.on 'all', (data) ->
	logQueue["temperature-#{data.location}"] = data.temperature if data.location? and data.temperature?
	logQueue["voltage-#{data.location}"] = data.voltage if data.location? and data.voltage?
