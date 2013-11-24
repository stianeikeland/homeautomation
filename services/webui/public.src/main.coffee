window.onload = () ->

	flotOpts =
		lines:
			show: true
		points:
			show: false
		yaxis:
			position: 'right'
			tickDecimals: 0
			tickSize: 2
			autoscaleMargin: 0.1
			labelWidth: 35
		xaxis:
			mode: "time"
			timezone: "browser"
		crosshair:
			mode: "xy"
		grid:
			hoverable: true
		legend:
			position: "nw"

	plotOptsOverride =
		"voltage":
			yaxis:
				tickSize: null

	sensorlist = ['livingroom-bookshelf', 'refrigerator', 'bedroom', 'outside', 'termostat']
	statuslist = ['heating']
	sensordata = {}

	graphs = [
		{name: "voltage", attribute: "voltage", sensors: ['livingroom-bookshelf', 'bedroom', 'refrigerator']}
		{name: "other", attribute: "temperature", sensors: ['refrigerator']}
		{name: "rooms", attribute: "temperature", sensors: ['termostat', 'livingroom-bookshelf', 'bedroom', 'outside']}
		]

	temperatureTemplate = Handlebars.compile $("#temperature-template").html()
	statusTemplate = Handlebars.compile $("#status-template").html()

	$("#graphs").prepend "<div><h4>#{x.name}:</h4><div class='graph' id='graph-#{x.name}'/></div>" for x in graphs
	$("#status").append temperatureTemplate {location: location, temperature: '--'} for location in sensorlist
	$("#status").append statusTemplate {name: name, status: '--'} for name in statuslist

	socket = io.connect '#{window.location.protocol}://#{window.location.host}'

	socket.on 'connect', () ->
		console.log "connected"

	socket.on 'initial', (data) ->
		sensordata = data
		plotGraph graph, sensordata for graph in graphs

		for sensor in sensorlist
			drawSensorStatus sensordata[sensor].slice(-1)[0] if sensordata[sensor]?[0]?


	prepareGraphData = (sensor, attribute, data) ->
		datapoints = _.map data, (x) -> [new Date(x.timestamp), x[attribute]]
		{label: sensor, data: datapoints}


	plotGraph = (graph, data) ->
		console.info "Plotting #{graph.name}"
		opts =
			if graph.name of plotOptsOverride
			then _.merge {}, flotOpts, plotOptsOverride[graph.name]
			else flotOpts
		graphData = (prepareGraphData sensor, graph.attribute, data[sensor] for sensor in graph.sensors)

		$.plot "#graph-#{graph.name}", graphData, opts


	sensorSubscribe = (sensor) ->
		console.info "Subscribing to #{sensor} events."
		socket.on sensor, (data) ->
			console.log data
			sensordata[sensor].push data

			# TODO: only plot affected graphs
			plotGraph graph, sensordata for graph in graphs
			drawSensorStatus data


	setUpToolTip = () ->
		for x in graphs
			$("#graph-#{x.name}").bind 'plothover', (event, pos, item) ->
				$("#tooltip").remove()
				showToolTip item.pageX, item.pageY, "#{item.series.label}: #{item.datapoint[1]}" if item


	showToolTip = (x, y, contents) ->
		css = { top: y + 5, left: x + 5 }
		$('<div id="tooltip">' + contents + '</div>').css(css).appendTo("body").fadeIn(200)


	drawSensorStatus = (data) ->
		$("#status-#{data.location}").replaceWith temperatureTemplate data

	# Send termostat value to bus
	$('#termostatform').submit () ->
		form = $('#termostatform')
		hours = form.find('#hours').val()

		termostat=
			event: "termostat"
			type: "setoverride"
			temperature: form.find('#target').val()
			endtime: moment().add('hours', hours).toDate()

		socket.emit 'bus', termostat
		console.info "Setting termostat target #{termostat.temperature} for #{hours} hours."

		return false

	sensorSubscribe sensor for sensor in sensorlist
	setUpToolTip()
