forever = require 'forever-monitor'

serviceList = ["mcu-relay", "notification", "powercontrol", "logger", "event-triggers"]

createProcess = (app, path = 'services/') ->
	proc = new forever.Monitor "#{app}.coffee", {
		command: 'coffee',
		cwd: "#{path}#{app}/",
		logfile: "#{app}.log",
		spinSleepTime: 5000,
		uid: app
	}

	proc.on 'exit', () ->
		console.log "#{app} - Exit!"

	return proc

broker = createProcess 'broker', ''
broker.start()

services = []
services.push createProcess app for app in serviceList

app.start() for app in services
