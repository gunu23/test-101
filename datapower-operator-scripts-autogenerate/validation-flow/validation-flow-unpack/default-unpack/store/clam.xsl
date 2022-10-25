<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:dpconfig="http://www.datapower.com/param/config"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp dpconfig"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:include href="store:///dp/msgcat/xslt.xml.xsl" dp:ignore-multiple="yes"/>

  <dp:summary xmlns="">
    <operation>filter</operation>
    <description>Attachment Virus Scanning</description>
    <descriptionId>store.clam.dpsummary.description</descriptionId>
  </dp:summary>

  <!-- ICAP Server Address -->
  <xsl:param name="dpconfig:RemoteAddress" select="''"/>
  <dp:param name="dpconfig:RemoteAddress" type="dmHostname" xmlns="">
    <display>Remote Address</display>
    <displayId>store.clam.param.RemoteAddress.display</displayId>
    <description>Please enter the remote address of the Virus Scanner.</description>
    <descriptionId>store.clam.param.RemoteAddress.description</descriptionId>
  </dp:param>

  <!-- ICAP Server Port -->
  <xsl:param name="dpconfig:RemotePort" select="'1344'"/>
  <dp:param name="dpconfig:RemotePort" type="dmIPPort" xmlns="">
     <display>Remote Port</display>
     <displayId>store.clam.param.RemotePort.display</displayId>
     <description>Please enter the remote port of the Virus Scanner.</description>
     <descriptionId>store.clam.param.RemotePort.description</descriptionId>
  </dp:param>

  <!-- logging category -->
  <xsl:param name="dpconfig:LogCategory" select="'xsltmsg'"/>
  <dp:param name="dpconfig:LogCategory" type="dmReference" reftype="LogLabel" xmlns="">
    <display>Log Category</display>
    <displayId>store.clam.param.LogCategory.display</displayId>
    <description>Please select the log category for Virus Scanner logs.</description>
    <descriptionId>store.clam.param.LogCategory.description</descriptionId>
  </dp:param>

  <xsl:template match="/*">
    <xsl:variable name="attachments" select="dp:variable('var://local/attachment-manifest')"/>

    <dp:accept/>

    <xsl:for-each select="$attachments/manifest/attachments/attachment">

      <xsl:variable name="location">
        <xsl:choose>
          <xsl:when test="uri">
            <xsl:value-of select="uri"/>
          </xsl:when>
          <xsl:when test="header/name = 'Content-Location'">
            <xsl:value-of select="header[name='Content-Location']/value"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_NOURIFORATTACH}"/>
            <dp:reject>Invalid Attachment</dp:reject>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- how to specify binary attachments? -->
      <xsl:variable name="binarydata">
        <dp:url-open target="{concat($location,'?Encode=base64')}"/>
      </xsl:variable>

      <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="notice" dp:id="{$DPLOG_XSLT_SCANNINGATTACH}" >
        <dp:with-param value="{$location}"/>
      </xsl:message>

      <dp:reject>Could not scan</dp:reject>
      <xsl:variable name="attachment">
        <dp:url-open target="{concat('icap://',$dpconfig:RemoteAddress,':',$dpconfig:RemotePort,'/srv_clamav')}" response="responsecode" data-type="base64">
          <xsl:value-of select="$binarydata/base64"/>
        </dp:url-open>
      </xsl:variable>
      <xsl:if test="$attachment/url-open/responsecode = '201'">
        <xsl:message dp:type="{$dpconfig:LogCategory}" dp:priority="error" dp:id="{$DPLOG_XSLT_VIRUSINATTACH}">
          <dp:with-param value="{$location}"/>
        </xsl:message>
        <dp:reject override="true">Virus Found</dp:reject>
        <!-- <dp:set-variable name="'var://service/error-subcode'" value="'0x01d30005'" /> -->
        <dp:set-variable name="'var://service/error-subcode'" value="30605317"/>
      </xsl:if>
      <xsl:if test="$attachment/url-open/responsecode = '200'">
        <dp:accept/>
      </xsl:if>


    </xsl:for-each>

  </xsl:template>

</xsl:stylesheet>

