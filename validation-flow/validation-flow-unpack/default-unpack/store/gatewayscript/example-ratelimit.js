/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2016,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

/*
  This script demonstrate the basic usage of ratelimit module
  It creates a ratelimit that restrict the access rate to 3 requests per minute
  for each individual client IP address
*/

var rl = require('ratelimit'),
    sm = require('service-metadata');

// Generate the key based on client IP address.
// The key could be generated based on any information that can uniquely identify the transaction
var key = sm.transactionClient;

// create rate object - 3 request per 60 seconds. New tokens are added to the 
// rate object with a fixed interval. 
var rate = rl.rateCreate(key, 3, 60, 'fixed');

// alternative way to create rate: 
// var rate = rl.rateCreate({key: key, tokens: 3, interval: 60, intervalType: 'fixed'});

// enforce the ratelimit check
rate.remove(1, function(err, remaining, reset){
    if(err){
        console.error('error:'+err);
        session.reject('Rate Exceeded\n');
    }else{
        console.info('ratelimit check ok, remain:' + remaining);
    }
})

