//
// Licensed Materials - Property of IBM
// IBM WebSphere DataPower Appliances
// Copyright IBM Corporation 2015,2016. All Rights Reserved.
//
//
//==============================================================================
//GatewayScript Example:  Custom JWT Verify or Decrypt
//==============================================================================
// Example: JWK retrieved via a remote URL 
//
// Input:
//  <input>
//    <parameter name="jwt">...</parameter>
//    <parameter name="message"/>...</parameter>
//    <parameter name="AAAJWTValidator">...</parameter>
//  </input>
//
// Expected Return Value: 
// XML:   <result>
// output result is a string
// [{'verify':'keyMaterial','decrypt','keyMaterial'}]
// [{'verify':'keyMaterial'}]
// [{'decrypt','keyMaterial'}]
//
//  keyMaterial supported format are the standard JOSE setKey format
//          [name:xxxx | sskey:xxxx | ski:xxxx | {JWK JSON Object}]
//
var jwt     = require('jwt');
var jose    = require('jose');
var trans = require('x-dp-native-transform');
var transform = require('transform');

try {
    //session.input.readAsXML(function(error, nodelist) {
    session.input.readAsXML(function(error, nodelist) {
        if(error){ 
            console.error("readAsXML failed"); 
            throw(error);
        } else {
            if(nodelist !== null) {
                var theDoc = nodelist.item(0).parentNode;
                var jwtToken = 'undefined';
                new Promise (function(resolve,reject) {
                    transform.xpath('/input/parameter[@name="jwt"]/text()',theDoc,function(err,nodelist){
                        if(err) reject(err);
                        else {
                            if(nodelist.length > 0)
                                jwtToken = XML.stringify({omitXmlDeclaration: true},nodelist.item(0));
                            resolve();
                        }
                    })
                    
                }).then (function(){
                    var theRemoteJWKURL = '';
                    var jwtsplit      = jwtToken.split(".");  
                    var decodedheader = JSON.parse(jose.base64urldecode(jwtsplit[0]));
                    console.debug("decodedheader: " + JSON.stringify(decodedheader));
                    var alg = decodedheader['alg'];
                    switch(alg){
                        case 'RSA1_5': 
                            theRemoteJWKURL = 'http://127.0.0.1:30054/getalice2048bitRSAcertJWK';
                            break;
                        default:
                            break;
                    }
                    var jwk = new readJWKRemote(theRemoteJWKURL);

                    jwk.then (function(result) {
                       var keys = [];
                       // Example: Use the JWK retrieved above
                       keys.push({"verify":result});
                       // Example: Use name of crypto object
                       //keys.push({"verify":'Alice2048cert'});
                       keys.push({"decrypt":'Alice2048key'});
                       console.debug('keys: ' + JSON.stringify(keys));
                       session.output.write(JSON.stringify(keys));
                    })
                    .catch ( function(error) {
                        console.error(error);
                        session.output.write(error);
                    });
                }).catch (function(error){
                    console.error(error);
                    session.output.write(error);
                });
            }
        }
    });
}catch(e){
    console.error(e);
    session.output.write(e);
    return;
}

//==============================================================================
//Example:  Retrieve JWK via Remote URL
//==============================================================================

var urlopen = require('urlopen');
var url     = require('url')

function readJWKRemote(remoteloc, sslprofile) {
 var url_options = { target : remoteloc, method: 'GET', timeout:60 };
 
 if (typeof sslprofile != 'undefined')
     url_options = { target : remoteloc, sslClientProfile: sslprofile, method: 'GET', timeout:60 };

 return new Promise(function (resolve, reject) {
     try {
         urlopen.open(url_options, function(error, response) {
             if (error) {
                 reject('unable to fetch key from url : ' + url_options.target);
             }
             else {
                 var responseStatusCode = response.statusCode;
                 var responseReasonPhrase = response.reasonPhrase;
                 console.log("Response status code: " + responseStatusCode);
                 console.log("Response reason phrase: " + responseReasonPhrase);
                 // reading response data
                 response.readAsJSON(function(error, responseData){
                     if (error){
                         console.error("Unable to read from url");
                         reject('unable to read key from url:' + url_options.target) ;
                     } 
                     resolve(responseData);
                 });
             }
         });
     } 
     catch(urlopenerror) {
         console.error(urlopenerror);
         reject(urlopenerror);
     }
 });    
}