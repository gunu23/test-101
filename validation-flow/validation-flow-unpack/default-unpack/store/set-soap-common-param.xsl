<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    Set common SOAP actor related parameters.
    Please do NOT include this file directly, include it via 
      store:///set-soap-sender-param.xsl or
      store:///set-soap-receiver-param.xsl
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
  <xsl:import href="store:///dp/msgcat/crypto.xml.xsl" dp:ignore-multiple="yes"/>
  <xsl:param name="dpconfig:actor-role-id" select="/.."/>
  <dp:param name="dpconfig:actor-role-id" type="dmString" xmlns="">
    <display>SOAP Actor/Role Identifier</display>
    <displayId>store.set-soap-common-param.param.actor-role-id.display</displayId>
    <summary>Specify the SOAP Actor/Role Identifier for the WS-Security Security header</summary>
    <description markup="html">
        Specify the identifier for the SOAP1.1 actor or SOAP1.2 role in
        processing a WS-Sec Security Header. This is only effective when a SOAP message
        is being used for WS-Security 1.0/1.1. Some well-known values are:
     <table>
        <tr>
            <td valign="left">http://schemas.xmlsoap.org/soap/actor/next</td>
            <td>Every one, including the intermediary and ultimate receiver, receives the message should be able to processing the Security header.</td>
        </tr>
        <tr>
            <td valign="left">http://www.w3.org/2003/05/soap-envelope/role/none</td>
            <td>No one should process the Security Header.</td>
        </tr>
        <tr>
            <td valign="left">http://www.w3.org/2003/05/soap-envelope/role/next</td>
            <td>Every one, including the intermediary and ultimate receiver, receives the message should be able to processing the Security header.</td>
        </tr>
        <tr>
            <td valign="left">http://www.w3.org/2003/05/soap-envelope/role/ultimateReceiver</td>
            <td>The message ultimate receiver can process the Security header. This is the default value if such setting is not configured.</td>
        </tr>
        <tr>
            <td valign="left">&lt;blank or empty string&gt;</td>
            <td>The empty string "" (without quotes) indicates that no "actor/role" identifier is configured.
                if there is no actor/role setting configured, the ultimateReceiver is assumed when processing the message,
                and no actor/role attribute will be added when generating the ws-security Security header.
                Please note: there should not be more than one Security headers omitting the actor/role identifier.</td>
        </tr>
        <tr>
            <td valign="left">USE_MESSAGE_BASE_URI</td>
            <td>The value "USE_MESSAGE_BASE_URI" without quotes indicates that the actor/role identifier
                will be the base url of the message, if the SOAP message is transported using HTTP,
                the base URI is the Request-URI of the http request.</td>
        </tr>
        <tr>
            <td valign="left">any other customized string</td>
            <td>You can input any string to identify the Security header's actor or role.</td>
        </tr>
      </table>    
    </description>
    <descriptionId>store.set-soap-common-param.param.actor-role-id.description</descriptionId>
    <default></default>
  </dp:param>

  <xsl:variable name="___soapnsuri___">
    <xsl:choose>
      <xsl:when test="/*[local-name()='Envelope']">
        <xsl:value-of select="namespace-uri(/*[local-name()='Envelope'])"/>
      </xsl:when>
      <xsl:otherwise>http://schemas.xmlsoap.org/soap/envelope/</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- The variable of the namespace prefix of the input SOAP Envelope element.
       For convenience, it will contain the ':' character if the SOAP Envelope element 
       has non-default prefix.
       -->
  <xsl:variable name="___soapnsprefix___">
    <!-- It is for sure the input is a SOAP message. we take the first element
         so that the codes will not get default ns for non-soap message. -->
    <xsl:variable name="prefix" select="substring-before(name(/*[1]), ':')"/>
    <xsl:if test="$prefix != ''">
      <xsl:value-of select="concat($prefix, ':')"/>
    </xsl:if>
  </xsl:variable>

  <!-- the constant for actor/role attribute name. -->
  <xsl:variable name="___actor_role_attr_name___">
    <xsl:choose>
      <xsl:when test="$___soapnsuri___='http://schemas.xmlsoap.org/soap/envelope/'">
        <xsl:value-of select="concat($___soapnsprefix___, 'actor')"/>
      </xsl:when>
      <xsl:when test="$___soapnsuri___='http://www.w3.org/2003/05/soap-envelope'">
        <xsl:value-of select="concat($___soapnsprefix___, 'role')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message dp:id="{$DPLOG_SOAP_UNRECOGNIZED_SOAP_VERSION}">
          <dp:with-param value="{string($___soapnsuri___)}"/>
        </xsl:message>
        <xsl:value-of select="concat($___soapnsprefix___, 'actor')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

</xsl:stylesheet>

