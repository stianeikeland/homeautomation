# Router / Central hub for home automation.
# Receives events and distributes via pub/sub

zmq = require 'zmq'

inputPort = 'tcp://*:8888'
outputPort = 'tcp://*:9999'

# Pull socket for incoming (push/pull), pub for outgoing (pub/sub)
input = zmq.socket 'pull'
output = zmq.socket 'pub'

input.identity = 'brokerin' + process.pid;
output.identity = 'brokerout' + process.pid;

output.bind outputPort, (err) ->
	throw err if err
	console.log "Publisher listening on #{outputPort}"

input.bind inputPort, (err) ->
	throw err if err
	console.log "Pull listening on #{inputPort}"

input.on 'message', (data) ->
	try
		jdata = JSON.parse data
		if not jdata.event?
			jdata.event = "unknown"

		strData = JSON.stringify jdata
		console.log "Relaying packet of type: #{jdata.event} >> #{strData}"
		output.send [jdata.event, strData]

	catch error
		console.log "Invalid data: #{error}"
		console.log data.toString()

process.on 'SIGINT', () ->
	input.close()
	output.close()










