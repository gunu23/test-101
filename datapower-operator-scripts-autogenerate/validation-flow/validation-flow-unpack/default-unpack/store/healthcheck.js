// Licensed Materials - Property of IBM
// IBM WebSphere DataPower Appliances
// Copyright IBM Corporation 2014. All Rights Reserved.
// US Government Users Restricted Rights - Use, duplication or disclosure
// restricted by GSA ADP Schedule Contract with IBM Corp.

var headers = require('header-metadata');

// set five parameters 
//       grp        = lb group to control
//       svr        = server name in lb group to toggle up/down
//       svrport    = server port of server in lb group
//       healthport = health port of server used to perform health check
//       evaluator  = evaluator metadata to help parse the response

var grp = session.parameters.grp;
var svr = session.parameters.svr;
var svrport = (session.parameters.svrport) ? session.parameters.svrport:0;
var healthport = (session.parameters.healthport) ? session.parameters.healthport:0;

// In the default case, mark the server as 'unhealthy' if it responded with a status code that is not 200
if (headers.current.statusCode != 200) {
    session.reject("Server " + svr + ":" + svrport + " from lb-group " + grp + " is unhealthy, status code: " + headers.current.statusCode);
}