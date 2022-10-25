<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    Set common WS-Security related parameters.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:S11="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:S12="http://www.w3.org/2003/05/soap-envelope"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    xmlns:dpquery="http://www.datapower.com/param/query"
    extension-element-prefixes="dp"
    exclude-result-prefixes="S11 S12 dp dpfunc dpconfig dpquery"
>
  <!-- this stylesheet will check the request's wssec-version, which depends on
       variable existing-security-header. In order for AAA to use the parameters
       defined within this xslt, we do not include the set-soap-*-param.xsl.

       If any customers want to use this stylesheet, do not forget to include
       store:///set-soap-sender-param.xsl or store:///set-soap-receiver-param.xsl 
       explicitly.
       -->
  <xsl:import href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>

  <xsl:param name="dpconfig:wssec-compatibility" select="'1.0'"/>
  <dp:param name="dpconfig:wssec-compatibility" type="dmCryptoWSSecVersion" xmlns="">
    <tab-override>basic</tab-override>
    <!-- Type definition is moved from drMgmt.xml.
         Since 3.6.0, the ws-sec version of the message always take precedence,
         as CLI command does not validate dp:param settings, (only webgui uses dp:param), 
         the other values of this type, such as "" or message decided, can be removed. -->
    <type name="dmCryptoWSSecVersion" base="enumeration" validation="range">
      <display>WS-Security Version</display>
      <displayId>store.set-wssec-common-param.param.wssec-compatibility.display</displayId>
      <description>The version of WS-Security to use.</description>
      <descriptionId>store.set-wssec-common-param.param.wssec-compatibility.description</descriptionId>
      <value-list>
        <value name="1.1">
          <display>1.1</display>
        </value>
        <value name="1.0" default="true">
          <display>1.0</display>
        </value>
        <value name="draft-12">
          <display>draft-12</display>
        </value>
        <value name="draft-13">
          <display>draft-13</display>
        </value>
      </value-list>
    </type>
  </dp:param>

  <xsl:param name="dpconfig:include-mustunderstand" select="'on'"/>
  <dp:param name="dpconfig:include-mustunderstand" type="dmToggle" xmlns="">
    <display>Include SOAP mustUnderstand</display>
    <displayId>store.set-wssec-common-param.param.include-mustunderstand.display</displayId>
    <description>Setting to 'on', the default, means a SOAP:mustUnderstand="1" attribute is
    included in the wsse:Security header.</description>
    <descriptionId>store.set-wssec-common-param.param.include-mustunderstand.description</descriptionId>
    <default>on</default>
  </dp:param>

  <!-- the dpconfig:wssec-id-ref-type param is common for all wssec sign/encrypt stylesheets. -->
  <xsl:param name="dpconfig:wssec-id-ref-type" select="'wsu:Id'"/>
  <dp:param name="dpconfig:wssec-id-ref-type" type="dmWSSecIDRefType" xmlns=""/>


  <!-- Sign/Encrypt compatibility switch -->
  <xsl:param name="dpconfig:compatibility" select="'standard'"/>
  <dp:param  name="dpconfig:compatibility" type="dmInteropWithVendor" xmlns="">
      <display>Compatibility</display>
      <displayId>store.set-wssec-common-param.param.compatibility.display</displayId>
      <description>Enable compatibility with specific third-party implementations.</description>
      <descriptionId>store.set-wssec-common-param.param.compatibility.description</descriptionId>
<!--
    <type name="dmCompatibility" base="enumeration" validation="range">
      <display>Compatibility</display>
      <description>Enable compatibility with specific third-party implementations.</description>
      <value-list>
        <value name="Standard" default="true">
          <display>Standard</display>
        </value>
        <value name="Microsoft">
          <display>Microsoft IIS</display>
        </value>
      </value-list>
    </type>
-->
  </dp:param>

  <xsl:variable name="compat">
    <xsl:choose>
      <xsl:when test="$dpconfig:compatibility = 'microsoft'">
        <xsl:value-of select="'iis'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'standard'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>


  <!-- Determine the version of ws-security we're creating based on what was configured
       and on any existing Security header.  If there's already a Security header
       present then we must use that version because we don't want to mix versions.
       -->
  <xsl:variable name="wssec-version">
    <xsl:choose>
      <xsl:when test="$existing-security-header">
        <xsl:variable name="existing-security-namespace"
          select="namespace-uri($existing-security-header)"/>
        <xsl:variable name="new-ver">
          <xsl:choose>
            <xsl:when test="$existing-security-namespace='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'">
              <xsl:text>1.0</xsl:text>
            </xsl:when>
            <xsl:when test="$existing-security-namespace='http://schemas.xmlsoap.org/ws/2002/07/secext'">
              <xsl:text>draft-12</xsl:text>
            </xsl:when>
            <xsl:when test="$existing-security-namespace='http://schemas.xmlsoap.org/ws/2003/06/secext'">
              <xsl:text>draft-13</xsl:text>
            </xsl:when>
            <!-- The wssec 1.1 namespace is not directly used by the wsse:Security element. -->
            <xsl:otherwise>
              <xsl:message dp:id="{$DPLOG_SOAP_UNRECOGNIZED_NS}" dp:priority="error">
                <dp:with-param value="{string($existing-security-namespace)}"/>
              </xsl:message>
              <xsl:value-of select="string($existing-security-namespace)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="string($new-ver) != string($dpconfig:wssec-compatibility)">
          <xsl:message dp:id="{$DPLOG_SOAP_MATCHING_NS}">
            <dp:with-param value="{string($new-ver)}"/>
            <dp:with-param value="{string($dpconfig:wssec-compatibility)}"/>
          </xsl:message>
        </xsl:if>
        <xsl:value-of select="$new-ver"/>
      </xsl:when>

      <!-- Then determine the version we're creating based on what was configured. -->
      <xsl:when test="$dpconfig:wssec-compatibility = '1.0'">
        <xsl:text>1.0</xsl:text>
      </xsl:when>
      <xsl:when test="$dpconfig:wssec-compatibility = 'draft-12'">
        <xsl:text>draft-12</xsl:text>
      </xsl:when>
      <xsl:when test="$dpconfig:wssec-compatibility = 'draft-13'">
        <xsl:text>draft-13</xsl:text>
      </xsl:when>
      <xsl:when test="$dpconfig:wssec-compatibility = '1.1'">
        <xsl:text>1.1</xsl:text>
      </xsl:when>     
      <xsl:otherwise>
        <xsl:message dp:id="{$DPLOG_SOAP_UNRECOGNIZED_PARAM}">
            <dp:with-param value="{string($dpconfig:wssec-compatibility)}"/>
        </xsl:message>
        <xsl:text>1.0</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="wsse-uri">
    <xsl:choose>
      <xsl:when test="($wssec-version = '1.0') or ($wssec-version = '1.1')">
        <!-- wssec 1.1 still uses the 1.0 wsu URI -->
        <xsl:text>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd</xsl:text>
      </xsl:when>
      <xsl:when test="$wssec-version = 'draft-13'">
        <xsl:text>http://schemas.xmlsoap.org/ws/2003/06/secext</xsl:text>
      </xsl:when>
      <xsl:when test="$wssec-version = 'draft-12'">
        <xsl:text>http://schemas.xmlsoap.org/ws/2002/07/secext</xsl:text>
      </xsl:when>
      <xsl:when test="$wssec-version != ''">
        <!-- the variable contains the existing ws-sec uri. -->
        <xsl:value-of select="string($wssec-version)"/>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="wsu-uri">
    <xsl:choose>
      <xsl:when test="($wssec-version = '1.0') or ($wssec-version = '1.1')">
        <xsl:text>http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd</xsl:text>
      </xsl:when>
      <xsl:when test="$wssec-version = 'draft-13'">
        <xsl:text>http://schemas.xmlsoap.org/ws/2003/06/utility</xsl:text>
      </xsl:when>
      <xsl:when test="$wssec-version = 'draft-12'">
        <xsl:text>http://schemas.xmlsoap.org/ws/2002/07/utility</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

</xsl:stylesheet>

