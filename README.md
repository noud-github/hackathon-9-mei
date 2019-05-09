# Task 3

## End result

Run `grunt update-version 1.0.1` to update the version in all relevant files.

Run `grunt licensed-artifact` to build an artifact containing a license key that can be validated using the `license-keys.json` file.

## Tasks

- Create a. `update-version` command that updates the version to it's first argument in the following files:
  - `source-files/index.php`
  - `source-files/classes/class.php`
  - `source-files/js/script.js`
- Create a `licensed-artifact` command that
  - generates a random 64 character string to serve as a license key.
  - replaces `"SUPER_SECRET_KEY_HERE"` in `source-files/classes/class.php` with that key.
  - builds a full artifact as performed in task 2.
  - resets the license key to `"SUPER_SECRET_KEY_HERE"` in the source code.
  - updates or creates a `license-keys.json` file that contains an array of license keys.
    - if the file already exists new keys should be appended to it.
