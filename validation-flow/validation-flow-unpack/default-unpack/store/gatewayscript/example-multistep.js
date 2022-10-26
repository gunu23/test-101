/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2016,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

var ms = require('multistep');

/**
 * Use promise to make functions to be executed sequentially.
 */
var ctx1 = session.createContext('example-multistep-ctx1');
new Promise( function(resolve, reject) {

    // 1st call
    ms.callRule('gws_call_rule_1', session.input, ctx1, function (error) {
        if (error) {
            throw error;
        }
        resolve();
    });

}).then( function() {return new Promise(function(resolve, reject) {

    // 2nd call
    ms.callRule('gws_call_rule_1', ctx1, session.output, function (error) {
        if (error) {
            throw error;
        }
        resolve();
    });

}).then( function() {return new Promise(function(resolve, reject) {
    
    // 3rd call - null means NULL context
    ms.callRule('gws_call_rule_1', null, null, function (error) {
        if (error) {
            throw error;
        }
        resolve();
    });

}).then( function() {
    console.log("DONE");
    // the output is written in 2nd call
})})});
