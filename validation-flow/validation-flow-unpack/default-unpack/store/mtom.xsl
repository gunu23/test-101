<?xml version="1.0" encoding="utf-8"?>
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
                extension-element-prefixes="dp"
                exclude-result-prefixes="dp dpconfig">

  <xsl:output method="xml"/>

  <dp:summary xmlns="">
    <operation>xform</operation>
    <description>Message Transmission Optimization Mechanism</description>
    <descriptionId>store.mtom.dpsummary.description</descriptionId>
  </dp:summary>

  <xsl:param name="dpconfig:mtompolicy" select="''"/>
  <dp:param name="dpconfig:mtompolicy" type="dmReference" reftype="MTOMPolicy" xmlns="">
    <display>MTOM Policy</display>
    <displayId>store.mtom.param.mtompolicy.display</displayId>
    <description>MTOM Policy</description>
    <descriptionId>store.mtom.param.mtompolicy.description</descriptionId>
  </dp:param>

  <xsl:include href="store:///dp/mtom.xsl" dp:ignore-multiple="yes"/>

  <xsl:template match="/">
    <xsl:variable name="policystring" select="dp:mtom-policy($dpconfig:mtompolicy)"/>
    <xsl:call-template name="mtom-implementation">
      <xsl:with-param name="policyname" select="$dpconfig:mtompolicy"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
