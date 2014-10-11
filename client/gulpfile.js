var gulp      = require('gulp');
var gutil     = require('gulp-util');
var connect   = require('gulp-connect');
var gulpif    = require('gulp-if');
var coffee    = require('gulp-coffee');
var concat    = require('gulp-concat');
var tplCache  = require('gulp-angular-templatecache');
var jade      = require('gulp-jade');
var less      = require('gulp-less');

gulp.task('appJS', function() {
  // concatenate compiled .coffee files and js files
  // into build/app.js
  gulp.src(['!./app/**/*_test.js','./app/**/*.js','!./app/**/*_test.coffee','./app/**/*.coffee'])
    .pipe(gulpif(/[.]coffee$/, coffee({bare: true}).on('error', gutil.log)))
    .pipe(concat('app.js'))
    .pipe(gulp.dest('./build'))
});

gulp.task('testJS', function() {
  // Compile JS test files. Not compiled.
  gulp.src([
      './app/**/*_test.js',
      './app/**/*_test.coffee'
    ])
    .pipe(
      gulpif(/[.]coffee$/,
        coffee({bare: true})
        .on('error', gutil.log)
      )
    )
    .pipe(gulp.dest('./build'))
});

gulp.task('templates', function() {
  // combine compiled Jade and html template files into 
  // build/template.js
  gulp.src(['!./app/index.jade', '!./app.index.html',
      './app/**/*.html', './app/**/*.jade'])
      .pipe(gulpif(/[.]jade$/, jade().on('error', gutil.log)))
      .pipe(tplCache('templates.js',{standalone:true}))
      .pipe(gulp.dest('./build'))
});

gulp.task('appCSS', function() {
  // concatenate compiled Less and CSS
  // into build/app.css
  gulp
    .src([
      './app/**/*.less',
      './app/**/*.css'
    ])
    .pipe(
      gulpif(/[.]less$/,
        less({
          paths: [
            './bower_components/bootstrap/less'
          ]
        })
        .on('error', gutil.log))
    )
    .pipe(
      concat('app.css')
    )
    .pipe(
      gulp.dest('./build')
    )
});

gulp.task('libJS', function() {
  // concatenate vendor JS into build/lib.js
  gulp.src([
    './bower_components/lodash/dist/lodash.js',
    './bower_components/jquery/dist/jquery.js',
    './bower_components/angular/angular.js',
    './bower_components/lodash/dist/lodash.js',
    './bower_components/bootstrap/dist/js/bootstrap.js',
    './bower_components/leaflet/dist/leaflet-src.js',
    './bower_components/angular-leaflet/dist/angular-leaflet-directive.js',
    './bower_components/bootstrap-material-design/scripts/ripples.js',
    './bower_components/angular-route/angular-route.js',
    './bower_components/leaflet-layerjson/dist/leaflet-layerjson.src.js'
    ]).pipe(concat('lib.js'))
      .pipe(gulp.dest('./build'));
});

gulp.task('libCSS',
  function() {
  // concatenate vendor css into build/lib.css
  gulp.src([
    './bower_components/bootstrap/dist/css/bootstrap.css',
    './bower_components/bootstrap-material-design/css-compiled/*.css',
    './bower_components/bootstrap-material-design/icons/icons-material-design.css',
    './bower_components/leaflet/dist/leaflet.css',
    './bower_components/fontawesome/css/font-awesome.css'
  ])
      .pipe(concat('lib.css'))
      .pipe(gulp.dest('./build'));
});

gulp.task('index', function() {
  gulp.src(['./app/index.jade', './app/index.html'])
    .pipe(gulpif(/[.]jade$/, jade().on('error', gutil.log)))
    .pipe(gulp.dest('./build'));
});

gulp.task('watch',function() {

  // reload connect server on built file change
  gulp.watch([
      'build/**/*.html',        
      'build/**/*.js',
      'build/**/*.css'        
  ], function(event) {
      return gulp.src(event.path)
          .pipe(connect.reload());
  });

  // watch files to build
  gulp.watch(['./app/**/*.coffee', '!./app/**/*_test.coffee', './app/**/*.js', '!./app/**/*_test.js'], ['appJS']);
  gulp.watch(['./app/**/*_test.coffee', './app/**/*_test.js'], ['testJS']);
  gulp.watch(['!./app/index.jade', '!./app/index.html', './app/**/*.jade', './app/**/*.html'], ['templates']);
  gulp.watch(['./app/**/*.less', './app/**/*.css'], ['appCSS']);
  gulp.watch(['./app/index.jade', './app/index.html'], ['index']);
});

gulp.task('connect', connect.server({
  root: ['build'],
  port: 9000,
  livereload: true
}));

gulp.task('default', ['connect', 'appJS', 'testJS', 'templates', 'appCSS', 'index', 'libJS', 'libCSS', 'watch']);