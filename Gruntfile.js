/*global module:false*/
const sass = require('node-sass');

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    zip: {'using-cwd': {cwd: 'artifacts', dest: 'dist/bundle.zip', src: ['artifacts/index.php', 'artifacts/assets/**']}},
    sass: {
      options: {
        implementation: sass,
        sourceMap: false
      },
      dist: {
        files: {
          'artifacts/assets/css/conditional-style.css': 'source-files/css/conditional-style.scss',
          'artifacts/assets/css/style.css': 'source-files/css/style.scss'
        }
      }
    },
    copy: {
      main:{
        files: [
          {
            expand: true,
            cwd: 'source-files',
            src: 'css/vendor/*.css',
            dest: 'artifacts/assets',
          },
          {
            expand: true,
            cwd: 'source-files',
            src: 'js/vendor/*.js',
            dest: 'artifacts/assets',
          },
          {
            expand: true,
            cwd: 'source-files',
            src: 'classes/*.php',
            dest: 'artifacts/assets',
          },
          {
            expand: true,
            cwd: 'source-files',
            src: 'index.php',
            dest: 'artifacts',
          },
        ]
      }
    },
    uglify: {
      options: {
        mangle: false
      },
      my_target: {
        files: [{
          expand: true,
          cwd: 'tmp',
          src: '*.js',
          dest: 'artifacts/assets/js'
        }]
      }
    },
    clean: {
      before: ['dist','artifacts','tmp'],
      after: ['artifacts','tmp']
    },
    babel: {
      options: {
        sourceMap: true,
        presets: ['@babel/preset-env']
      },
      dist: {
        files: {
          'tmp/script.js': 'source-files/js/script.js',
          'tmp/conditional-script.js': 'source-files/js/conditional-script.js',
        }
      }
    }
  });

  // Load tasks here.
  grunt.loadNpmTasks('grunt-zip');
  grunt.loadNpmTasks('grunt-sass');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-babel');
  // Define aliases here.
  grunt.registerTask('default', 'My default task description', ['sass', 'copy']);
  grunt.registerTask('artifact', 'My default task description', ['clean:before','sass', 'copy', 'babel','uglify','zip','clean:after']);
};
