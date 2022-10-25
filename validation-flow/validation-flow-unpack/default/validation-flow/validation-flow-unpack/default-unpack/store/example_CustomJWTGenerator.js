/**
 * Licensed Materials - Property of IBM
 * (C) Copyright IBM Corporation 2016,2017.
 * US Government Users Restricted Rights - Use, duplication or disclosure
 * restricted by GSA ADP Schedule Contract with IBM Corp.
 **/

var jwt     = require('jwt');
var jose    = require('jose');
var hm      = require('header-metadata');

//==============================================================================
// Custom JWT Generator
//
// EXAMPLE: This Custom JWT Generator is configured in AAA Policy Postprocessing
//          as:  Run postprocessing custom processing = on
//               Custom processing = store:///example_CustomJWTGenerator.js
//
// The GatewayScript program is called from the AAA XSLT stylesheet using the
//   dp:gatewayscript extension function.
//
//     dp:gatewayscript(script, input, return-error, parameters)
//          script
//              (xs:string) The location of the GatewayScript program as a string.
//          input
//              A nodeset containing $postprocinput which is the AAA input to 
//              the Post Processing step including $identity, $credentials, 
//              $mappedcreds, $resource, $mappedres and $authorize
//              This contants of each will vary based on the preceeding 
//              AAA Policy Stages configuration and results.
//          return-error 
//              (xs:boolean)  false 
//          parameters
//              (xs:nodeset) An empty nodeset.
//
// Sample call:
// <xsl:variable name="result">
//   <dp:gatewayscript script="store:///example_CustomJWTGenerator.js" 
//                     input="$input"  
//                     return-error="false()"/>
// </xsl:variable>
//
// Example 1 of input:
//    @note In this example, the input nodeset contains a jwt in the identity.  
//          A JWT was processed in the EI AAA Policy Stage.
//
//  <container>
//      <identity>
//            <entry type="jwt">
//                <jwt type="bearer">...</jwt>
//                <username>...</username>
//                <jwt action="misc">
//                    <original token="...">
//                        <claims>{"iss":"...","sub":"...","aud":"...",...}</claims>
//                    </original>
//                    <header>
//                        <alg>...</alg>
//                    </header>
//                    <validated-claims>
//                        <iss>...</iss>
//                        <sub>...</sub>
//                        <aud>...</aud>
//                    </validated-claims>
//                    <username-claim>
//                        <sub>...</sub>
//                    </username-claim>
//                </jwt>
//            </entry>
//        </identity>
//        <credentials>
//            <entry type="oauth-or-oidc" subtype="jwt">
//                <username>...</username>
//                <validated-claims>
//                    <iss>...</iss>
//                    <sub>...</sub>
//                    <aud>...</aud>
//                </validated-claims>
//            </entry>
//        </credentials>
//        <mapped-credentials type="none" au-success="true">
//            <entry type="oauth-or-oidc" subtype="jwt">
//                <username>...</username>
//                <validated-claims>
//                    <iss>...</iss>
//                    <sub>...</sub>
//                    <aud>...</aud>
//                </validated-claims>
//            </entry>
//        </mapped-credentials>
//        <resource>
//            <item type="original-url">...</item>
//        </resource>
//        <mapped-resource type="none">
//            <resource>
//                <item type="original-url">...</item>
//            </resource>
//        </mapped-resource>
//        <approved>...</approved>
//        <message/>
//        <server-name>..</server-name>
//    </container>
//
// Example 2 of input
// @note In this example, the input nodeset identity is http-basic-auth type  
//    <container>
//            <identity>
//                <entry type="http-basic-auth">
//                    <username>...</username>
//                    <password sanitize="true">...</password>
//                    <configured-realm>...</configured-realm>
//                </entry>
//            </identity>
//            <credentials>
//                <entry type="xmlfile">
//                    <OutputCredential xmlns="http://www.datapower.com/AAAInfo">...</OutputCredential>
//                </entry>
//            </credentials>
//            <mapped-credentials type="none" au-success="true">
//                <entry type="xmlfile">
//                    <OutputCredential xmlns="http://www.datapower.com/AAAInfo">...</OutputCredential>
//                </entry>
//            </mapped-credentials>
//            <resource>
//                <item type="original-url">...</item>
//            </resource>
//            <mapped-resource type="none">
//                <resource>
//                    <item type="original-url">...</item>
//                </resource>
//            </mapped-resource>
//            <approved>...</approved>
//            <message/>
//            <server-name>...</server-name>
//            <SAML-signing-alg>...</SAML-signing-alg>
//            <SAML-signing-hash>...</SAML-signing-hash>
//    </container>
//
// Expected Return Value:
//  The custom JWT Generator should set the JWT token in the HTTP header 
//  as a bearer token.
//
// If successful write the JWT token to output
//        session.output.write("<jwt>" + token + "</jwt>");
//==============================================================================
try {
    session.input.readAsXML(function(error, nodelist) {
        if(error) {
            throw(error);
        }
        // The NodeList that results is accessed with methods of the DOM API, 
        // XML, and other modules, as provided by GatewayScript.
        var xmlInput = XML.stringify({ omitXmlDeclaration: true },nodelist);
        console.debug('nodelist: ' +xmlInput );
        var doc = XML.parse(xmlInput);
        // For example: get the mapped-resource element
        var mapres = doc.documentElement.getElementsByTagName('mapped-resource');
        console.debug("mapped-resource node" + XML.stringify({ omitXmlDeclaration: true },mapres));
        // Call the function to build the JWT
        doCreateJWT();
    });
}catch(e){
    console.error(e);
    session.reject(e.errorMessage);
    return;
}

//==============================================================================
// In this example I will retrieve a JWK version of the Alice2048key to sign the
// JWT instead of using the key object by name
//==============================================================================
function doCreateJWT() {
        var signAlg  = 'RS256';
        //var signKey  = 'Alice2048key';
        var enc       = 'A128CBC-HS256';
        var encAlg   = 'RSA1_5';
        var encCert  = 'Alice2048cert';

        var now         = Math.floor(new Date()/1000) ;
        var claims = {'iss': 'datapower',
                      'sub': 'admin',
                      'exp': now + parseInt(3600),
                      'nbf': now,
                      'iat': now,
                      'jti': 'id12345',
                      'aud': 'datapower',
                      "customClaim1":["claimValue1","claimValue2","claimValue3"],
                      "customClaim2":"true",
                      "customClaim3":"123"};
        //claims['jti'] = uuid;
        
        // JWK could be hard coded, but in this example I am retrieving a JWK
        // via a remote URL
        var theRemoteJWKURL = 'http://127.0.0.1:30054/getalice2048bitRSAkeyJWK';
        var jwk = new readJWKRemote(theRemoteJWKURL);

        jwk.then (function(result) {
            // Create instance of JWT Encoder
            var encoder = new jwt.Encoder(claims);

            // If sign is required build the required JWSHeader
            // and tell the JWT Encoder to perform the sign step 1st
            // NOTE: using jwk obtained via readJWKRemote() above
            var jwsHeader = jose.createJWSHeader(result, signAlg);
            console.debug("jwsHdr " + JSON.stringify(jwsHeader));
            encoder.addOperation('sign', jwsHeader);
            
            // If encrypt is required build the required JWE Header
            // and tell the JWT Encoder to perform the encryption step next
            var jweHeader = jose.createJWEHeader(enc);
            jweHeader.setProtected('alg', encAlg);
            var key = 'name:' + encCert;
            jweHeader.setKey(key);
            // set 'cty' header to "JWT" to comply with the JWT spec, if nested
            jweHeader.setProtected('cty','JWT');
            console.debug(" jweHdr " + JSON.stringify(jweHeader));
            encoder.addOperation('encrypt', jweHeader);
            
            // Generate the encoded JWT via the methods specified above
            encoder.encode(function(error, token) {
                  if (error) {
                      session.output.write('error creating JWT: ' + error + ' ');
                      throw(error);
                  } 
                  else {
                      // If successful write the JWT token to the output
                      console.debug("JWT token: " + token);
                      session.output.write("<jwt>" + token + "</jwt>");
                      var jwtBearerToken = 'Bearer ' + token;
                      // Set the JWT token in the HTTP Authorization header as a bearer token
                      var headers  = require('header-metadata');
                      headers.response.set('Authorization',jwtBearerToken);
                      headers.current.set('Authorization',jwtBearerToken);
                      var authHdr = headers.current.get('Authorization');
                      console.debug("AuthHeader: " + authHdr);
                  }
                });

        })
        .catch ( function(error) {
            console.error(error);
            session.output.write(error);
        });
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
