/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2015,2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

/* Requiring fs module, everything starts from here */
var fs = require('fs');
var results = {};

// Create a temporary file name with path of temporary:///temp_#, # is a 5 digit serial number.
// Temporary files have a default lifetime of 10 seconds.
// Please note that this is not asynchronous
var temporary_filename = fs.temporary ();

/**
 * Use promise to make functions to be executed sequentially.
 */
new Promise( function(resolve, reject) {
/*** Promise section ***/

// Write a file. You can only create or write files in temporary:///
fs.writeFile (temporary_filename, 'hello world', function(error) {
  if(error) {
    throw error; // throw and stop processing
  }
  results.writeFile = "temporary file successfully created";
  resolve(); // promise resolved
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

fs.exists (temporary_filename, function(exists) {
  if(exists) {
    results.exists = "temporary file does exist";
    resolve(); // promise resolved
  } else {
    results.exists = "temporary file does not exist";
    reject(); // promise resolved
  }
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

// Or you can write a file using options to specify parameters
// Writing a file that already exists overlays its contents.
// Only the following 3 property names are supported in writeFile()
var options = {
  file: temporary_filename,
  data: 'hello world via options',
  TTL: 0 // [optional] 0 makes it permanent
}
fs.writeFile (options, function(error) {
  if(error) {
    throw error; // throw and stop processing
  }
  resolve(); // promise resolved
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

// The appendFile() is like writeFile(), only it appends data to the end of the file
fs.appendFile (temporary_filename, '.\n Appended information.', function(error) {
  if(error) {
    throw error;  // throw and stop processing
  }
  results.appendFile = "temporary file successfully appended";
  resolve(); // promise resolved
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

// Read a file
fs.readFile (temporary_filename, function(error, buffer) {
  if(error) {
    throw error; // throw and stop processing
  }
  // temporary_filename has been read as a buffer, you can use it now
  results.readFile = buffer.toString();
  resolve(); // promise resolved
}); 

// Or you can use the options object to specify paramaters
//fs.readFile ({file: temporary_filename, encoding: 'base64'}, function(error, buffer) {
//  if(error) {
//    throw error;
//  }
//});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

var data = {hello: 'world - json'};
fs.writeFile('temporary:///example.json', data, function(error) {
  if(error) {
    throw error; // throw and stop processing
  }
  // Read a file and parse it as JSON
  fs.readAsJSON ('temporary:///example.json', function(error, json) {
    if(error) {
      throw error; // throw and stop processing
    }
    // json is the parsed result of temporary_filename
    results.readAsJSON = json;
    resolve(); // promise resolved
  }); 
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

var xml = '<test>hello world - xml</test>';
fs.writeFile('temporary:///example.xml', xml, function(error) {
  if(error) {
    throw error; // throw and stop processing
  }
  // Read a file and parse it as XML
  fs.readAsXML ('temporary:///example.xml', function(error, xmldoc) {
    if(error) {
      throw error; // throw and stop processing
    }
    // xml is the parsed result of temporary_filename
    results.readAsXML = xmldoc;
    resolve(); // promise resolved
  });
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

// Rename a file
fs.rename (temporary_filename, 'temporary:///dummy.txt', function(error) {
  if(error) {
    throw error; // throw and stop processing
  }
  resolve(); // promise resolved
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

// Truncate the file to specified length
fs.truncate ('temporary:///dummy.txt', 12, function(error) {
  if(error) {
    throw error; // throw and stop processing
  }
  resolve(); // promise resolved
});

/*** Promise section ***/
}).then( function() {return new Promise(function(resolve, reject) {
/*** Promise section ***/

// Delete a file
fs.unlink ('temporary:///dummy.txt', function(error) {
  if(error) {
    throw error; // throw and stop processing
  }
  resolve(); // promise resolved
});

/*** Promise section ***/
}).then( function() {session.output.write(results);})})})})})})})})})});
/*** Promise section ***/
