/**
 * Licensed Materials - Property of IBM
 * IBM WebSphere DataPower Appliances
 * Copyright IBM Corporation 2015,2016. All Rights Reserved.
 **/
//==============================================================================
// Generate Custom JWT Claims
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
//              The contents of each will vary based on the preceeding 
//              AAA Policy Stages configuration and results.
//          return-error 
//              (xs:boolean)  false 
//          parameters
//              (xs:nodeset) An empty nodeset.
//
// Example of input:
//  <input>
//      <subject>...</subject>
//      <uuid>...</uuid>
//      <JWTGenerator>...</JWTGenerator>
//      <identity>
//          <entry type="http-basic-auth">
//              <username>...</username>
//              <password sanitize="true">...</password>
//              <configured-realm>...</configured-realm>
//          </entry>
//      </identity>
//      <credentials>
//          <entry type="xmlfile">
//              <OutputCredential xmlns="http://www.datapower.com/AAAInfo">...</OutputCredential>
//          </entry>
//      </credentials>
//      <mapped-credentials type="none" au-success="true">
//          <entry type="xmlfile">
//              <OutputCredential xmlns="http://www.datapower.com/AAAInfo">...</OutputCredential>
//          </entry>
//      </mapped-credentials>
//      <resource>
//          <item type="original-url">...</item>
//      </resource>
//      <mapped-resource type="none">
//          <resource>
//              <item type="original-url">...</item>
//          </resource>
//      </mapped-resource>
//  </input>
//
// Expected Return Value:
//  The claims are a string representing a set of claims as a JSON object
// A claim is represented as a name/value pair consisting of a 
//   Claim Name and a Claim Value.
// A Claim Name is always a string.
// A Claim Value can be any JSON value.
//
//==============================================================================
//==============================================================================
// GatewayScript Example:  Generating JWT Custom Claims
//==============================================================================
// NOTE: Any changes here should be mirrored in 
//          store:///example_CreateJWTCustomClaims.js
//==============================================================================
try {
    session.input.readAsXML(function(error, nodelist) {
        if(error) {
            throw(error);
        }
        // The NodeList that results is accessed with methods of the DOM API, 
        // XML, and other modules, as provided by GatewayScript.
        var xmlInput = XML.stringify({ omitXmlDeclaration: true },nodelist);
        console.debug('nodelist: ' + xmlInput );
        var doc = XML.parse(xmlInput);
        // For example: get the sub element
        var subject = doc.documentElement.getElementsByTagName('subject');
        console.debug("sub node" + XML.stringify({ omitXmlDeclaration: true },subject));
        // Example Result returned: 
        // <subject>....</subject>
        // For example: get the uuid element
        var uuid = doc.documentElement.getElementsByTagName('uuid');
        console.debug("uuid node" + XML.stringify({ omitXmlDeclaration: true },uuid));
        // Example Result returned: 
        // <uuid>....</uuid>
        // For example: get the mapped-resource element
        var mapres = doc.documentElement.getElementsByTagName('mapped-resource');
        console.debug("mapped-resource node" + XML.stringify({ omitXmlDeclaration: true },mapres));
        // Example Result returned: 
        //      <mapped-resource type="none">
        //          <resource>
        //              <item type="original-url">....</item>
        //          </resource>
        //      </mapped-resource>
         var claims = [
         {"customClaim1":["claimValue1","claimValue2","claimValue3"]},
         {"customClaim2":"true"},
         {"customClaim3":"123"}
          ];
         console.debug("CustomClaims: "+JSON.stringify(claims));
         session.output.write(JSON.stringify(claims));
    });
}catch(e){
    console.error(e);
    session.reject(e.errorMessage);
    return;
}
