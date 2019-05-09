// Set the version so other plugins may detect it.
window.plugin.version = "1.0.0";

/**
 * Capitalize the first letter of a string.
 *
 * @param   {string} string The string to capitalize.
 *
 * @returns {string}        The string with the first letter capitalized.
 */
function firstToUpperCase( string ) {
    return string.charAt( 0 ).toUpperCase() + string.slice( 1 );
}

/**
 * Strips HTML from a string.
 *
 * @param {string} string  The string to strip HTML from.
 *
 * @returns {string} The string with HTML stripped.
 */
function stripHTML( string ) {
    const tmp = document.createElement( "DIV" );
    tmp.innerHTML = string;
    return tmp.textContent || tmp.innerText || "";
}
