NodeProwl = (require 'prowl').Prowl

class Prowl

	constructor: (apikey) ->
		@prowl = new NodeProwl(apikey)

	send: (subject, content, callback) ->

		data =
			priority: NodeProwl.NORMAL,
			application: "Home Automation",
			event: subject,
			description: content

		@prowl.add data, callback

exports.Prowl = Prowl