<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2010. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    Provide common WS-Sec related SOAP receiver parameters and libs.
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
  <xsl:include href="store:///set-soap-common-param.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///wssec-utilities.xsl" dp:ignore-multiple="yes"/>

  <!-- the constant for actor/role attribute name. -->
  <xsl:variable name="resolved-actor-role-id" select="dpfunc:get-actor-role-value($dpconfig:actor-role-id, '1')"/>
      <!-- TODO: When the service has provided the configuration, we will resolve the value with those configuration too.
      <xsl:value-of select="dpfunc:get-actor-role-value($dpconfig:actor-role-id, '1')"/>
  </xsl:variable>
  -->

  <!-- the following settings will index Security headers by actor and/role.
       They are actually ws-sec related.
       -->
  <xsl:key name="soap-actor-role" 
           match="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security']
                        [dpfunc:match-actor-role(., $resolved-actor-role-id)]" 
           use="$resolved-actor-role-id" />

  <!-- If there is an existing Security element then use the first one.
       If there are two security headers with same actor/role or omitting actor/role attribute,
       then send out a fault message.
       -->
  <xsl:variable name="existing-security-header" select="key('soap-actor-role', $resolved-actor-role-id)"/>

</xsl:stylesheet>

