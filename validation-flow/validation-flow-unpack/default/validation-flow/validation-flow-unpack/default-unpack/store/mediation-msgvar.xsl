<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:func="http://exslt.org/functions"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp"
>
  <xsl:import href="store:///mediation-util.xsl"/>

  <xsl:param name="dpconfig:Message" select="''"/>
  <xsl:param name="dpconfig:PolicyName" select="''"/>
  <xsl:param name="dpconfig:PolicyID" select="''"/>
  <xsl:param name="dpconfig:PolicyURL" select="''"/>

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:template match='/'>
    
    <!-- Define the string fragments that we intend to replace as constants -->
    <xsl:variable name="kPolicyName"           select="'${PolicyName}'" />
    <xsl:variable name="kPolicyID"             select="'${PolicyId}'" />
    <xsl:variable name="kPolicyURL"            select="'${PolicyURL}'" />
    <xsl:variable name="kServiceURL"           select="'${ServiceURL}'" />
    <xsl:variable name="kServicePath"          select="'${ServicePath}'" />
    <xsl:variable name="kServiceProtocol"      select="'${ServiceProtocol}'" />
    <xsl:variable name="kContextTransactionId" select="'${ContextTransactionId}'" />
    <xsl:variable name="kSLAId"                select="'${SLAId}'" />
    <xsl:variable name="kSystemDateTime"       select="'${SystemDateTime}'" />

    <!-- Collect the information that we will merge into the input -->
    <xsl:variable name="slaId"                select="dpfunc:getSLAId(.)" />

    <!-- Add space at the beginning and end of the string so it will split() properly --> 
    <xsl:variable name="input" select="concat(' ',$dpconfig:Message, ' ')" />
    
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub($input, $kServiceURL, dp:variable('var://service/URL-in'))"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kServicePath, dp:variable('var://service/URI'))"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kServiceProtocol, dp:variable('var://service/protocol'))"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kContextTransactionId, dp:variable('var://service/transaction-id'))"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kSLAId, $slaId)"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kSystemDateTime, date:date-time())"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kPolicyName, $dpconfig:PolicyName)"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kPolicyID, $dpconfig:PolicyID)"/>
    <dp:set-local-variable name="'output'" value="dpfunc:stringSub(dp:local-variable('output'), $kPolicyURL, $dpconfig:PolicyURL)"/>

    <!-- Strip spaces from the beginning and end of the output -->
    <xsl:value-of select="normalize-space(dp:local-variable('output'))" />
   
  </xsl:template>
  
  <!-- ********************* -->
  <!-- Get SLA Id            -->
  <!-- ********************* -->
  <func:function name="dpfunc:getSLAId">
    <xsl:param name="input" select="''"/> <!-- don't really need this param, but dp:transform needs a second parameter -->

    <xsl:variable name="slaIdentity" select="dp:transform('store:///sla-credential-class-policy-enforcement.xsl', $input)" />

    <xsl:variable name="result" >
      <xsl:choose>
        <xsl:when test="string-length($slaIdentity//value) > 0">
          <xsl:value-of select="$slaIdentity//value"/>
        </xsl:when>
        <xsl:when test="string-length($slaIdentity//value) > 0">
          <xsl:text>Anonymous</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>No SLAId</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <func:result select="$result"/>
  </func:function>


</xsl:stylesheet>
