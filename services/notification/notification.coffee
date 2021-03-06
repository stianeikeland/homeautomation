# Notification service for home automation system

nconf      = require 'nconf'
Email      = (require './lib/email').Email
Prowl      = (require './lib/prowl').Prowl
MessageBus = (require 'homeauto').MessageBus

# Set up zmq socket, connect and subscribe to notification events
bus = new MessageBus {
	subscribe: ["notification"],
	identity: "notification-#{process.pid}"
}

notificationActions =
	email: "email",
	mail: "email",
	push: "prowl",
	prowl: "prowl",
	ios: "prowl",
	default: "email"

# Load configuration settings (argv > env > config.json)
nconf.argv().env().file {file: 'config.json'}

# Set up emailer
email = new Email nconf.get 'email'

# Set up Prowl (iOS push)
prowl = new Prowl (nconf.get 'prowl').apikey

emailTarget = (target, pkg) ->
	console.log "Emailing notification to #{target}"
	email.send target, pkg.subject, pkg.content, (err, msg) ->
		console.log err or msg

handlePkg = (pkg) ->
	pkg.subject ?= ""
	pkg.content ?= ""

	switch pkg.action
		when "email"
			targets = pkg.targets or (nconf.get 'defaultEmailTargets') or []
			targets = [targets] if typeof targets is "string"

			emailTarget target, pkg for target in targets

		when "prowl"
			prowl.send pkg.subject, pkg.content, (status) ->
				console.log "Prowl sent - #{status}"

		else
			console.log "Unknown service.."


bus.on 'event', (topic, pkg) ->
	pkg.action = pkg.action or notificationActions.default

	if not notificationActions[pkg.action]?
		pkg.action = notificationActions.default
	else
		pkg.action = notificationActions[pkg.action]

	handlePkg pkg

process.on 'SIGINT', () ->
	bus.close()
