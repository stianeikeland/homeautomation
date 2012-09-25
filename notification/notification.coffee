require 'coffee-script'

nconf   = require 'nconf'
zmq     = require 'zmq'
Email   = (require './lib/email').Email

# Load configuration settings (argv > env > config.json)
nconf.argv()
	.env()
	.file {file: 'config.json'}

# Set up emailer
email = new Email nconf.get 'email'

# Set up zmq socket, connect and subscribe to notification events
brokerSubAddr = 'tcp://127.0.0.1:9999'
brokerSub = zmq.socket 'sub'
brokerSub.identity = 'notification' + process.pid

brokerSub.connect brokerSubAddr, (err) ->
	throw err if err
	console.log 'Sub Broker connected!'

brokerSub.subscribe 'notification'

brokerSub.on 'message', (topic, data) ->
	try
		pkg = JSON.parse data
		
		console.dir pkg
		
	catch error
		console.dir error


#email.send "Stian Eikeland <stian@eikeland.se>", "Subject", "Content", (err, msg) ->
#	console.log (err || msg)