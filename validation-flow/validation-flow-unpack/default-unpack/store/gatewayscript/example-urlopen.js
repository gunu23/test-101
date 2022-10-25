/*
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2014,2016. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
*/

var urlopen = require ('urlopen');

// define urlopen user agent options
var ua_options = {
    'persistentConnection': true,
    'allowCompression': false,
    'followRedirect': true,
    'maxRedirects': 8,
    'http10Only': false,
    'rewriteHost': false
};
var httpUA = new urlopen.HttpUserAgent(ua_options);

// get and set user agent options via .get() and .set()
var setting = httpUA.get();
httpUA.set('rewriteHost', true);

// define the urlopen options
var options = {
    target: 'http://127.0.0.1:42410/echo',
    // if target is https, supply a sslClientProfile
    // target: 'https://127.0.0.1:42409/echo',
    // sslClientProfile: 'alice-sslClient',
    method: 'post',
    headers: { 'X-My-Header1' : 'value1', 'X-My-Header2' : 'value2' },
    contentType: 'application/json',
    timeout: 60,
    data: "Hello DataPower GatewayScript",
    agent: httpUA,
};

// open connection to target and send data over
urlopen.open (options, function (error, response) {
    if (error) {
        // an error occurred during request sending or response header parsing
        session.output.write ("urlopen connect error: " + JSON.stringify(error));
    } else {
        // read response data
        // get the response status code
        var responseStatusCode = response.statusCode;
        if (responseStatusCode == 200) {
            response.readAsBuffer(function(error, responseData) {
                if (error) {
                    // error while reading response or transferring data to Buffer
                    session.output.write("readAsBuffer error: " + JSON.stringify(error));
                } else {
                    session.output.write(responseData);
                } 
            });
        } else {
            session.output.write ("urlopen target return statusCode " + responseStatusCode);
        }
    }
}); // end of urlopen.open()
