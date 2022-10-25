<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp xsl">
<!--
 * Licensed Materials - Property of IBM
 * IBM WebSphere DataPower Appliances
 * Copyright IBM Corporation 2015,2016. All Rights Reserved.
 **/
//==============================================================================
// This XSLT is called from the AAA XSLT stylesheet 
// Input includes the following:  (Example of http-basic-auth identity entry)
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
// Generate Custom JWT Claims
// Expected Return Value:
//  The claims are a string representing a set of claims as a JSON object
// A claim is represented as a name/value pair consisting of a 
//   Claim Name and a Claim Value.
// A Claim Name is always a string.
// A Claim Value can be any JSON value.
//
//==============================================================================
//==============================================================================
// XSL Example:  Generating JWT Custom Claims
//==============================================================================
-->
  <xsl:output method="text"/>

  <xsl:param name="customClaims">
    <claim><Name>customClaim1</Name><Value>claimValue1</Value></claim>
    <claim><Name>customClaim2</Name><Value>true</Value></claim>
    <claim><Name>customClaim3</Name><Value>123</Value></claim>
  </xsl:param>
  
  <xsl:template match="/">
    <xsl:message dp:priority="debug">Input nodes <xsl:copy-of select="/input"/></xsl:message>
    <xsl:choose>
    <xsl:when test="/input/subject = 'geekyb'">
      <xsl:message dp:priority="debug">sub value is <xsl:copy-of select="/input/subject"/></xsl:message>
    </xsl:when>
    <xsl:otherwise>
        <xsl:message dp:priority="debug">sub value is <xsl:copy-of select="/input/subject"/></xsl:message>
        <xsl:text>[</xsl:text>
        <xsl:for-each select="$customClaims/claim">
        <xsl:variable name="theName"><xsl:value-of select="Name"/></xsl:variable>
        <xsl:variable name="theValue"><xsl:value-of select="Value"/></xsl:variable>
        <xsl:text>{"</xsl:text>
        <xsl:value-of select="$theName"/>
        <xsl:text>":"</xsl:text>
        <xsl:value-of select="$theValue"/>
        <xsl:text>"}</xsl:text>
        <xsl:choose>
            <xsl:when test="position() = last()"></xsl:when>
            <xsl:otherwise><xsl:text>,</xsl:text></xsl:otherwise>
        </xsl:choose>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
