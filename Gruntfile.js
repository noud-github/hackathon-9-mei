/*global module:false*/
const sass = require('node-sass');

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    zip: {'dist/bundle.zip' : ['index.html', 'assets/script.js', 'assets/style.css']},
    sass: {
      options: {
        implementation: sass,
        sourceMap: false
      },
      dist: {
        files: {
          'assets/style.css': 'source-files/style.scss'
        }
      }
    },
    copy: {
      main: {
        expand: true,
        cwd: 'source-files',
        src: '*.js',
        dest: 'assets/',
      },
    },
  });

  // Load tasks here.
  grunt.loadNpmTasks('grunt-zip');
  grunt.loadNpmTasks('grunt-sass');
  grunt.loadNpmTasks('grunt-contrib-copy');
  // Define aliases here.
  grunt.registerTask('default', 'My default task description', ['sass', 'copy', 'zip']);

};
