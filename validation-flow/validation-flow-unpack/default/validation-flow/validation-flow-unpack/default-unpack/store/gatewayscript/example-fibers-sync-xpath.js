/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2016,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

var transform = require('transform');
var Fiber = require('fibers');

var xmlString = 
            '<?xml version="1.0"?>\n' +
            '<library>\n' +
            '<book id="1">\n' +
            '  <title>DataPower Admin</title>\n' +
            '  <author>Hermann</author>\n' +
            '  <media>Hardcover</media>\n' +
            '</book>\n' +
            '<book id="2">\n' +
            '  <title>DataPower Development</title>\n' +
            '  <author>Tim</author>\n' +
            '  <media>Hardcover</media>\n' +
            '</book>\n' +
            '<book id="3">\n' +
            '  <title>DataPower Capacity</title>\n' +
            '  <author>Hermann</author>\n' +
            '  <media>eBook</media>\n' +
            '</book>\n' +
            '</library>\n';

var domTree = XML.parse(xmlString);

var xpathSync = function(obj) {
    transform.xpath(obj.expr, obj.tree, function(error, result) {
        if (error) {
            throw new Error(error);
        } else {
            // resume execution, pass the result to the yielding fiber
            fiber.run(result);
        }
    });
};

var fiber = Fiber(function() {
    var params = {
        'expr': '//book[author/text()="Hermann"]',
        'tree': domTree
    };
    xpathSync(params);
    // halt execution here, waiting for transform.xpath to call run().
    var n1 = fiber.yield();
    // n1 = 2 books matched for author of Hermann - id of 1 & 3

    params = {
        'expr': '//book[media/text()="Hardcover"]',
        'tree': n1
    };
    xpathSync(params);
    // halt execution here, waiting for transform.xpath to call run().
    var n2 = fiber.yield();
    // n2 = 1 book matched for media of Hardcover - id of 1
    
    session.output.write(XML.stringify(n2));
});
fiber.run(); // start execute the fiber
// If the fiber is yielding, the main program continues to run from here.
