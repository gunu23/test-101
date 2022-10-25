/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2014,2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
 */
var assert = require('assert');
var transform = require('transform');

// read data from the wire as an XML nodeList object
session.input.readAsXML(function(error, nodelist) {
    assert.notStrictEqual(nodelist.length, 0);
    assert.ok(nodelist.item(0).parentNode);
    assert.strictEqual(nodelist.item(0).parentNode.nodeType, Node.DOCUMENT_NODE);

    var theDoc = nodelist.item(0).parentNode;
    var xsltOption = {
        'location': 'store:///identity.xsl',  // stylesheet location
        'xmldom': theDoc,                     // the document node to apply the XSL
        'honorAbort': true,      // when true, if dp:abort() is invoked in XSL,
                                 // the transaction will be aborted
    };

    // start the xslt execution with the xsltOption
    transform.xslt(xsltOption, function(error, nodelist, isAbort) {
        if (error) {
            session.output.write(
                "execution error for '" + JSON.stringify(xsltOption) + "': \n" +
                "error: " + JSON.stringify(error) + "\n" + "isAbort: " + isAbort);
        } else {
            // if xslt execution was success, the transformation result will be 
            // put into the nodelist (a DOM NodeList structure)
            if (nodelist && nodelist.length > 0)
                session.output.write(nodelist); // write the XML to output
            else
                session.output.write("transform.xslt() returns nothing!");
        }
    });
});
