<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
     Insert WS-Policy and HMAC signature on it into SOAP header.
     -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" 
  xmlns:wsse-d12="http://schemas.xmlsoap.org/ws/2002/07/secext"
  xmlns:wsse-d13="http://schemas.xmlsoap.org/ws/2003/06/secext"
  xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
  xmlns:wsu-d12="http://schemas.xmlsoap.org/ws/2002/07/utility"
  xmlns:wsu-d13="http://schemas.xmlsoap.org/ws/2003/06/utility"
  xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"
  xmlns:dpp="http://www.datapower.com/policy"
  xmlns:dp="http://www.datapower.com/extensions"
  xmlns:dpconfig="http://www.datapower.com/param/config"
  extension-element-prefixes="dp"
  exclude-result-prefixes="dp dpconfig SOAP"
  >
  <dp:summary xmlns="">
    <operation>xform</operation>
    <description>Insert WS-Policy and HMAC signature on it into SOAP header.</description>
    <descriptionId>store.policy-sign-hmac-wssec.dpsummary.description</descriptionId>
  </dp:summary>

  <xsl:output method="xml"/>

  <xsl:include href="store:///dp/sign-hmac.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:sigalg" select="'hmac-sha1'"/>
  <dp:param name="dpconfig:sigalg" type="dmCryptoHMACSigningAlgorithm" xmlns=""/>

  <xsl:param name="dpconfig:hashalg" select="'sha1'"/>
  <dp:param name="dpconfig:hashalg" type="dmCryptoHashAlgorithm" xmlns=""/>

  <xsl:include href="store:///set-key.xsl" dp:ignore-multiple="yes"/>

  <!-- policy variables -->
  <xsl:include href="store:///dp/policy-common.xsl" dp:ignore-multiple="yes"/>

  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

<xsl:template match="SOAP:Envelope">
  <SOAP:Envelope>
    <xsl:copy-of select="@*"/>
    <xsl:if test="not (SOAP:Header)">
      <xsl:call-template name="SOAP:Header">
        <xsl:with-param name="new" select="true()"/>
      </xsl:call-template>
    </xsl:if>  
    <xsl:apply-templates select="*"/>
  </SOAP:Envelope>
</xsl:template>

<xsl:template name="SOAP:Header" match="SOAP:Header">
  <xsl:param name="new" select="false()"/>  
  <SOAP:Header>
    <xsl:copy-of select="$policy-body"/>
    <xsl:if test="not (wsse:Security | wsse-d12:Security | wsse-d13:Security)">
      <xsl:call-template name="wsse:Security">
        <xsl:with-param name="new" select="true()"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="not($new)">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*"/>
    </xsl:if>
  </SOAP:Header>  
</xsl:template>

<xsl:template name="wsse:Security" match="wsse:Security">
  <xsl:param name="new" select="false()"/>
  <wsse:Security>
    <xsl:if test="not($new)">
      <xsl:copy-of select="@*"/>
    </xsl:if>
    <xsl:call-template name="dp-sign-hmac">
      <xsl:with-param name="node" select="$policy-body" />
      <xsl:with-param name="refuri" select="concat('#', $policy-id)" />
      <xsl:with-param name="keyid" select="concat('name:', $key)"/>
      <xsl:with-param name="sigalg" select="$dpconfig:sigalg"/>
      <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
      <xsl:with-param name="c14nalg" select="'exc-c14n'"/>
    </xsl:call-template>
    <xsl:if test="not($new)">
      <xsl:copy-of select="*"/>
    </xsl:if>
  </wsse:Security>
</xsl:template>

<xsl:template match="wsse-d12:Security">
  <wsse-d12:Security>
    <xsl:copy-of select="@*"/>
    <xsl:call-template name="dp-sign-hmac">
      <xsl:with-param name="node" select="$policy-body" />
      <xsl:with-param name="refuri" select="concat('#', $policy-id)" />
      <xsl:with-param name="keyid" select="concat('name:', $key)"/>
      <xsl:with-param name="sigalg" select="$dpconfig:sigalg"/>
      <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
      <xsl:with-param name="c14nalg" select="'exc-c14n'"/>
    </xsl:call-template>
    <xsl:copy-of select="*"/>
  </wsse-d12:Security>
</xsl:template>

<xsl:template match="wsse-d13:Security">
  <wsse-d13:Security>
    <xsl:copy-of select="@*"/>
    <xsl:call-template name="dp-sign-hmac">
      <xsl:with-param name="node" select="$policy-body" />
      <xsl:with-param name="refuri" select="concat('#', $policy-id)" />
      <xsl:with-param name="keyid" select="concat('name:', $key)"/>
      <xsl:with-param name="sigalg" select="$dpconfig:sigalg"/>
      <xsl:with-param name="hashalg" select='$dpconfig:hashalg'/>
      <xsl:with-param name="c14nalg" select="'exc-c14n'"/>
    </xsl:call-template>
    <xsl:copy-of select="*"/>
  </wsse-d13:Security>
</xsl:template>

</xsl:stylesheet>
