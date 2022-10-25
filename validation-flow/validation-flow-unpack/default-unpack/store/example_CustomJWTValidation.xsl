<!-- 
 * Licensed Materials - Property of IBM
 * IBM WebSphere DataPower Appliances
 * Copyright IBM Corporation 2015,2016. All Rights Reserved.
 **/
-->
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp">

<!-- 
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
//
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
//==============================================================================
// XSL Example:  Custom JWT Validation
//==============================================================================
 -->
  <xsl:template match="/">
    <!-- The JWT is can be found in the token attribute of the original element -->
    <!-- Example of how to obtain the JWT from the original header
    <xsl:variable name="theJWT" select="normalize-space(substring-after(dp:http-request-header('Authorization'), 'Bearer'))"/>
    -->
    <xsl:variable name="theJWT" select="normalize-space(substring-after(dp:http-request-header('Authorization'), 'Bearer'))"/>
    <xsl:variable name="issClaimValue"><xsl:value-of select="/result/jwt/validated-claims/iss"/></xsl:variable>
    <xsl:variable name="customClaimValue"><xsl:value-of select="/result/jwt/validated-claims/customClaim3"/></xsl:variable>

    <xsl:choose>
      <xsl:when test="$issClaimValue = 'datapower' and $customClaimValue = '123'">
        <result><verified ok='yes'/></result>
      </xsl:when>
      <xsl:otherwise>
        <result><verified ok='no'>
          <error_id>invalid_request</error_id>
          <error_description>Custom JWT Validation Failed</error_description>
          </verified></result>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>