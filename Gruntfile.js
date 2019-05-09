/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    zip: {'dist/bundle.zip' : ['index.html', 'source-files/script.js', 'source-files/style.scss']}

  });

  // Load tasks here.
  grunt.loadNpmTasks('grunt-zip');
  // Define aliases here.
  grunt.registerTask('default', 'My default task description', function() {
    grunt.log.writeln( 'This is the default grunt task, create a new task and configure.' );
  });

};
