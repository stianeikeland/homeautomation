window.onload = () ->

	flotOpts =
		lines:
			show: true
		points:
			show: false
		yaxis:
			min: 15
			max: 30
			tickDecimals: 0
		xaxis:
			mode: "time"
			timezone: "browser"
		crosshair:
			mode: "xy"
		grid:
			hoverable: true

	plotOptsOverride =
		"other":
			yaxis:
				min: -2
				max: 8

	sensorlist = ['livingroom-bookshelf', 'refrigerator', 'bedroom']
	sensordata = {}

	graphs = [
		{name: "rooms", sensors: ['livingroom-bookshelf', 'bedroom']},
		{name: "other", sensors: ['refrigerator']}
		]

	$("#graphs").prepend "<div class='graph' id='graph-#{x.name}'>" for x in graphs

	socket = io.connect 'http://127.0.0.1:8900'

	socket.on 'connect', () ->
		console.log "connected"

	socket.on 'initial', (data) ->
		sensordata = data
		plotGraph graph, sensordata for graph in graphs


	prepareGraphData = (sensor, data) ->
		datapoints = _.map data, (x) -> [new Date(x.timestamp), x.temperature]
		{label: sensor, data: datapoints}


	plotGraph = (graph, data) ->
		console.info "Plotting #{graph.name}"
		opts =
			if graph.name of plotOptsOverride
			then _.extend {}, flotOpts, plotOptsOverride[graph.name]
			else flotOpts
		graphData = (prepareGraphData sensor, data[sensor] for sensor in graph.sensors)

		$.plot "#graph-#{graph.name}", graphData, opts


	sensorSubscribe = (sensor) ->
		console.info "Subscribing to #{sensor} events."
		socket.on sensor, (data) ->
			sensordata[sensor] = data

			# TODO: only plot affected graphs
			plotGraph graph, sensordata for graph in graphs


	setUpToolTip = () ->
		for x in graphs
			$("#graph-#{x.name}").bind 'plothover', (event, pos, item) ->
				$("#tooltip").remove()
				showToolTip item.pageX, item.pageY, "#{item.series.label}: #{item.datapoint[1]}" if item


	showToolTip = (x, y, contents) ->
		css = { top: y + 5, left: x + 5 }
		$('<div id="tooltip">' + contents + '</div>').css(css).appendTo("body").fadeIn(200)

	sensorSubscribe sensor for sensor in sensorlist
	setUpToolTip()
