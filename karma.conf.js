module.exports = function(config) {
	config.set({
		frameworks: [ 'mocha', 'browserify' ],
		files: [ 'tests/*.spec.coffee' ],
		browsers: [ 'PhantomJS' ],
		preprocessors: {
			'**/*.coffee': [ 'browserify' ]
		},
		browserify: {
			debug: true,
			transform: [ 'coffeeify' ],
			extensions: [ '.coffee' ]
		}
	})
}
