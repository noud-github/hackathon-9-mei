# Task 2

## End result

Run `grunt artifact` to create a zip containing the following structure:

* assets
  * classes
    * class.php
    * interface.php
  * css
    * vendor
      * dependency.css
    * conditional-style.css (CSS not SASS)
    * style.css (CSS not SASS)
  * js
    * vendor
      * jquery.js (not minified twice)
      * mootools.js (not minified twice)
    * conditional-script.js
    * script.js
* index.php

## Tasks

- Copy multiple files at once
- Minify only the JavaScript files that require this
- Convert SASS to CSS only for files that require this
- Create an alias which combines multiple tasks
