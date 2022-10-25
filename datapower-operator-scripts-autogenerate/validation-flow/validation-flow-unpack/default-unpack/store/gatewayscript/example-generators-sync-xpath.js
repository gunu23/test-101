/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2015,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

var util = require('util');

// A simple function to wrap async to sync
function sync(gen) {
    // get the generator
    var it = gen();

    // the closure to iterate on the generator
    function next(err, result) {
        // If there is no error, then calling it.next() to give the control back
        // to the generator function. The return value of it.next() is an object
        // with 2 properties: done and value
        var n = err ? it.throw(err) : it.next(result);
        if (!n.done) {
            if (util.safeTypeOf(n.value) == 'function') {
                // if the value is a function, then calling it by providing the
                // function as the callback of the async call, which will call
                // the next() closure to give the control back to the generator
                // function.
                try {
                    n.value(function(err, result) {
                        next(err, result);
                    });
                } catch(e) {
                    next(e);
                }
            } else {
                // if the value is not a function, then return the value back
                // to the caller directly
                next(null, n.value);
            }
        }
    }

    // calling next() to start executing the generator
    next();
}

// wrap xpath operation to be synchronous
function xpathSync(expr, xmldom) {
    // return a function to yield back to the caller, i.e. the statement of it.next() in sync() above.
    return function(callback) {
        trans.xpath(expr, xmldom, callback);
    }
}

var xmlString = 
            '<?xml version="1.0"?>' +
            '<library>' +
            '<book id="1">' +
            '  <title>DataPower Admin</title>' +
            '  <author>Hermann</author>' +
            '  <media>Hardcover</media>' +
            '</book>' +
            '<book id="2">' +
            '  <title>DataPower Development</title>' +
            '  <author>Tim</author>' +
            '  <media>Hardcover</media>' +
            '</book>' +
            '<book id="3">' +
            '  <title>DataPower Capacity</title>' +
            '  <author>Hermann</author>' +
            '  <media>eBook</media>' +
            '</book>' +
            '</library>';

var domTree = XML.parse(xmlString);
var trans = require("transform");

sync(function*() {
    var nl1 = yield xpathSync("//book[author/text()='Hermann']", domTree);
    // 2 books matched for author of Hermann - id of 1 & 3

    var nl2 = yield xpathSync("//book[media/text()='Hardcover']", nl1);
    // 1 book matched for media of Hardcover - id of 1
    
    session.output.write(XML.stringify(nl2));
});