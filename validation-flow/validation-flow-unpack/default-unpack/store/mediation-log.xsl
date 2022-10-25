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
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp"
>
  <xsl:import href="store:///mediation-util.xsl"/>

  <xsl:param name="dpconfig:ID" select="''"/>
  <xsl:param name="dpconfig:LogPriority" select="''"/>
  <xsl:param name="dpconfig:Domain" select="''"/>
  <xsl:param name="dpconfig:Class" select="''"/>
  <xsl:param name="dpconfig:Type" select="''"/>
  <xsl:param name="dpconfig:Object" select="''"/>

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:template match='/'>
    <xsl:variable name="message" select="."/>

    <xsl:message dp:id="{$dpconfig:ID}"
                 dp:priority="{$dpconfig:LogPriority}"
                 dp:domain="{$dpconfig:Domain}"
                 dp:type="{$dpconfig:Type}"
                 dp:class="{$dpconfig:Class}"
                 dp:object="{$dpconfig:Object}">
        <dp:with-param value="{$message}"/>
    </xsl:message>
    
  </xsl:template>

</xsl:stylesheet>
