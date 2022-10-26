//
// Licensed Materials - Property of IBM
// IBM WebSphere DataPower Appliances
// Copyright IBM Corporation 2015,2016. All Rights Reserved.
//
//
//==============================================================================
//GatewayScript Example:  Custom JWT Validation
//==============================================================================
//
//==============================================================================
// Custom JWT Validation
// Example: JWT retrieved from Input data
//
//==============================================================================
// Custom JWT Validation
//
// Input:
//  <result>
//      <jwt action='..'>
//          <original token='..'> 
//              <claims exp=".." nbf="..">...</claims>
//          </original>
//          <header>...</header> 
//          <validated-claims>...</validated-claims>
//          <username-claim>...</username-claim>
//      </jwt>
//      <config>...</config> <<==JWTValidator
//  </result>

// Expected Return Value: 
// XML:   <result>
//        <verified ok='yes|no'>
//        <error_id>xxx</error_id>
//        <error_description>xxx</error_description>
//        </verified>
//        </result>   
//
//<error_id/><error_description/> are ignored when verified/@ok = 'yes'
//
var sm = require('service-metadata');
var hm = require('header-metadata');
var jwt     = require('jwt');
var jose    = require('jose');

var resultOK = "<result><verified ok='yes'/></result>";
var resultNOTOK = "<result><verified ok='no'><error_id>invalid_request</error_id><error_description>xxxx</error_description></verified></result>";

try {
    session.input.readAsXML(function(error, nodelist) {
        if(error){ 
            console.error("readAsXML failed"); 
            throw(error);
        } else {
            if(nodelist !== null) {
                var domTree = nodelist.item(0).parentNode;
        
                var xmlInput = XML.stringify({ omitXmlDeclaration: true },nodelist);
                console.debug('nodelist: ' + xmlInput );
                var doc = XML.parse(xmlInput);
        
                    // Example: Get the JWT from the Input paramters    
                var inputJWT = doc.getElementsByTagName("original").item(0).getAttributeNode("token").value;
                console.debug('inputJWT: ' + inputJWT );
        
                // Example: JWT retrieved from Authorization Bearer Header  
                // var authHeader = hm.current.get('Authorization');
                // var jwtToken = authHeader.replace(/^Bearer /g, '');
                // var xml = '';
                // var jwtsplit                = jwtToken.split(".");  
                // var decodedheader           = JSON.parse(jose.base64urldecode(jwtsplit[0]));
        
                var inputCLAIMS = doc.getElementsByTagName("validated-claims");
                    console.debug('inputCLAIMS: ' + XML.stringify({ omitXmlDeclaration: true },inputCLAIMS ));
        
                var issClaimValue     = doc.getElementsByTagName("iss").item(0).childNodes.item(0).nodeValue;
                var customClaimValue = doc.getElementsByTagName("customClaim3").item(0).childNodes.item(0).nodeValue;
                if(issClaimValue === 'datapower' && customClaimValue === '123') {
                console.debug(XML.parse(resultOK));
                session.output.write(XML.parse(resultOK));
                } else {
                        console.error(resultOK);
                    session.output.write(XML.parse(resultNOTOK));
                }
            }
            
        }
    });       
}catch(e){
    console.error(e);
    console.error(resultNOTOK);
    session.output.write(XML.parse(resultNOTOK));
    return;
}