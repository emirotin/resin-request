
/*
The MIT License

Copyright (c) 2015 Resin.io, Inc. https://resin.io.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 */
var token;

token = require('resin-token');


/**
 * @summary Get authorization header content
 * @function
 * @protected
 *
 * @description
 * This promise becomes undefined if no saved token.
 *
 * @returns {Promise<String>} authorization header
 *
 * @example
 * utils.getAuthorizationHeader().then (authorizationHeader) ->
 *		headers =
 *			Authorization: authorizationHeader
 */

exports.getAuthorizationHeader = function() {
  return token.get().then(function(sessionToken) {
    if (sessionToken == null) {
      return;
    }
    return "Bearer " + sessionToken;
  });
};


/**
 * @summary Get error message from response
 * @function
 * @protected
 *
 * @param {Object} response - node request response
 * @returns {String} error message
 *
 * @example
 * request
 *		method: 'GET'
 *		url: 'https://foo.bar'
 *	, (error, response) ->
 *		throw error if error?
 *		message = utils.getErrorMessageFromResponse(response)
 */

exports.getErrorMessageFromResponse = function(response) {
  if (response.body == null) {
    return 'The request was unsuccessful';
  }
  if (response.body.error != null) {
    return response.body.error.text;
  }
  return response.body;
};


/**
 * @summary Check if the status code represents an error
 * @function
 * @protected
 *
 * @param {Number} statusCode - status code
 * @returns {Boolean} represents an error
 *
 * @example
 * if utils.isErrorCode(400)
 *		console.log('400 is an error code!')
 */

exports.isErrorCode = function(statusCode) {
  return statusCode >= 400;
};
