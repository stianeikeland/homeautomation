
# Scraper for http://veret.gfi.uib.no/
# Run via cron

config = {
	subAddress: 'tcp://raspberrypi:9999'
	pushAddress: 'tcp://raspberrypi:8888'
}

request = require 'request'
cheerio = require 'cheerio'
bus = new (require 'homeauto').MessageBus config

req = {
	url: 'http://veret.gfi.uib.no/'
	headers:
		"User-Agent": 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.57.2 (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2'
}

bus.on "event", console.log

parse = (err, resp, body) ->
	process.exit 1 if err

	c = cheerio.load body
	obstables = c 'table[class=obstable]'

	parseAttribute = (attribute) ->
		parseFloat obstables.find("td:contains(#{attribute})").parent().children().eq(1).text()

	data =
		temperature: parseAttribute "Luftemperatur"
		windspeed: parseAttribute "Vindhastighet"
		humidity: parseAttribute "Relativ fuktighet"
		pressure: parseAttribute "Lufttrykk"
		precipitation: parseAttribute "Nedb&oslash;r"
		location: "outside"
		event: "sensor"

	bus.send data
	bus.close()


(setTimeout (() -> process.exit 2), 30000).unref()
request req, parse
