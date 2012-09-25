emailjs = require 'emailjs'
_ = require 'underscore'

class Email

	constructor: (userOptions = {}) ->
				
		defaultConfig =
			host: 'localhost',
			ssl: false,
			domain: 'localdomain.local',
			from: 'Home Automation <home@localdomain.local>'
						
		options = _.extend defaultConfig, userOptions
		
		@smtp = emailjs.server.connect options
		@from = options.from
		
	send: (target, subject, content, callback) ->
		
		mail =
			text: content,
			to: target,
			subject: subject,
			from: @from
		
		@smtp.send mail, callback


exports.Email = Email