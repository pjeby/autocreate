gulp = require('gulp')
mocha = require 'gulp-mocha'
coffee = require 'gulp-coffee'

package_name = JSON.parse(require('fs').readFileSync "package.json").name
main = "#{package_name}.litcoffee"

module.exports =
  build: build = ->
    gulp.src(main)
    .pipe coffee()
    #.on 'error', ->gutil.log
    .pipe gulp.dest('.')
    #.pipe filelog()

  test: test = gulp.series build, ->
    gulp.src 'spec.*coffee'
    .pipe mocha
        reporter: "spec"
        useColors: yes
        fullStackTrace: yes
        #bail: yes
    .on "error", (err) ->
        console.log err.toString()
        console.log err.stack if err.stack?
        @emit 'end'

  "default": gulp.series test, ->
    gulp.watch ['README.md', main, 'spec.*coffee'], test
