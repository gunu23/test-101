/*
  Licensed Materials - Property of IBM
  (C) Copyright IBM Corporation 2014,2017.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

var kv = require ('keyvalue');
var hm = require('header-metadata');

var owner = hm.current.get('DP-OWNER');


new Promise(function(resolve, reject) {
    kv.get(owner, function(err, result) {
        if (!err) {
            if  (result === null || result === 'NULL') 
                resolve("[]"); // not revoked
            else 
                resolve(result); // not revoked
        }
        else {
            resolve("[]"); // any error (it is a revoked)
        }
    });
})
.then (function(result) {
     session.output.write({ 
        contentType: 'application/json',
        currentStatusCode: 200
     });
     session.output.write(result);
})
.catch (function (error) {
    session.output.write({
        contentType: 'application/json',
        currentStatusCode: 200
    });
    session.output.write("{'error':'" + error + "'}");
});
