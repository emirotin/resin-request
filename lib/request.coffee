###
Copyright 2016 Resin.io

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###

###*
# @module request
###

Promise = require('bluebird')
request = require('request')
requestAsync = Promise.promisify(request)
url = require('url')
_ = require('lodash')
rindle = require('rindle')

errors = require('resin-errors')
settings = require('resin-settings-client')
token = require('resin-token')
utils = require('./utils')
progress = require('./progress')

prepareOptions = (options = {}) ->

	_.defaults options,
		method: 'GET'
		json: true
		strictSSL: true
		gzip: true
		headers: {}
		refreshToken: true

	if not options.baseUrl?
		options.url = url.resolve(settings.get('apiUrl'), options.url)

	Promise.try ->
		return if not options.refreshToken

		utils.shouldUpdateToken().then (shouldUpdateToken) ->
			return if not shouldUpdateToken

			exports.send
				url: '/whoami'
				refreshToken: false
			.catch (error) ->

				# At this point we're sure there is a saved token,
				# however the fact that /whoami returns 401 allows
				# us to safely assume the token is expired
				if error instanceof errors.ResinRequestError and error.statusCode is 401
					return token.get().then (sessionToken) ->
						token.remove().then ->
							throw new errors.ResinExpiredToken(sessionToken)

				throw error
			.get('body')
			.then(token.set)

	.then(utils.getAuthorizationHeader).then (authorizationHeader) ->
		if authorizationHeader?
			options.headers.Authorization = authorizationHeader
		return options

###*
# @summary Perform an HTTP request to Resin.io
# @function
# @public
#
# @description
# This function automatically handles authorizacion with Resin.io.
# If you don't have a token, the request is made anonymously.
# This function automatically prepends the Resin.io host, therefore you should pass relative urls.
#
# @param {Object} options - options
# @param {String} [options.method='GET'] - method
# @param {String} options.url - relative url
# @param {*} [options.body] - body
#
# @returns {Promise<Object>} response
#
# @example
# request.send
# 	method: 'GET'
# 	url: '/foo'
# .get('body')
#
# @example
# request.send
# 	method: 'POST'
# 	url: '/bar'
# 	data:
# 		hello: 'world'
# .get('body')
###
exports.send = (options = {}) ->

	# Only set a default timeout when doing a normal HTTP
	# request and not also when streaming since in the latter
	# case we might cause unnecessary ESOCKETTIMEDOUT errors.
	options.timeout ?= 30000

	prepareOptions(options).then(requestAsync).spread (response) ->

		if utils.isErrorCode(response.statusCode)
			responseError = utils.getErrorMessageFromResponse(response)
			utils.debugRequest(options, response)
			throw new errors.ResinRequestError(responseError, response.statusCode)

		return response

###*
# @summary Stream an HTTP response from Resin.io.
# @function
# @public
#
# @description
# This function emits a `progress` event, passing an object with the following properties:
#
# - `Number percent`: from 0 to 100.
# - `Number total`: total bytes to be transmitted.
# - `Number received`: number of bytes transmitted.
# - `Number eta`: estimated remaining time, in seconds.
#
# The stream may also contain the following custom properties:
#
# - `String .mime`: Equals the value of the `Content-Type` HTTP header.
#
# @param {Object} options - options
# @param {String} [options.method='GET'] - method
# @param {String} options.url - relative url
# @param {*} [options.body] - body
#
# @returns {Promise<Stream>} response
#
# @example
# request.stream
# 	method: 'GET'
# 	url: '/download/foo'
# .then (stream) ->
# 	stream.on 'progress', (state) ->
# 		console.log(state)
#
#		stream.pipe(fs.createWriteStream('/opt/download'))
###
exports.stream = (options = {}) ->
	prepareOptions(options).then(progress.estimate).then (download) ->
		if not utils.isErrorCode(download.response.statusCode)

			# TODO: Move this to resin-image-manager
			download.mime = download.response.headers['content-type']

			return download

		# If status code is an error code, interpret
		# the body of the request as an error.
		return rindle.extract(download).then (data) ->
			responseError = data or utils.getErrorMessageFromResponse(download.response)
			utils.debugRequest(options, download.response)
			throw new errors.ResinRequestError(responseError, download.response.statusCode)
