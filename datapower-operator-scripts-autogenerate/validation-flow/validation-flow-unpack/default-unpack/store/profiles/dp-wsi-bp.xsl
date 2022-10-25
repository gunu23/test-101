<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!-- 
    This stylesheet implements the WSI Basic Profile 1.0/1.1
    configuration conformance verification.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:dpfunc='http://www.datapower.com/extensions/functions'
                xmlns:dp="http://www.datapower.com/extensions"
                extension-element-prefixes="dp"
                exclude-result-prefixes="dpfunc dp">

    <xsl:include href="store:///dp/msgcat/mplane.xml.xsl"/>
    <xsl:import href="webgui:///webmsgcat.xsl"/>

    <!-- output options -->
    <xsl:output method="xml" encoding="utf-8" indent="yes"/>

    <dp:summary>
        <operation>conformance-checker</operation>
        <description>WS-I Basic Profile 1.0/1.1</description>
    </dp:summary>

    <!-- this can be set from the CLI to see debug output. -->
    <xsl:variable name="debug" select="dp:variable('var://system/soma/debug')"/>

    <xsl:template match="/">
      <xsl:if test="($debug &gt; 1)">
          <xsl:message dp:priority="info" dp:id="{$DPLOG_MPLANE_PROF_CONF_WSI}">
          </xsl:message>
      </xsl:if>

       <!-- The root element looks like:
              <input>
                <domain>
                <configuration>
                <locale>
              </input>

             The <domain> element specifies the domain that we are in. It is used by the BSP conformance checker, but NOT used by this stylesheet.
             The <configuration> element contains a series of configuration elements. 
             The <locale> element contains the language of details messages in the generated conformance report -->

      <ConformanceAnalysis>
        <xsl:variable name="config" select="'{http://www.datapower.com/param/config}'"/>

        <xsl:variable name="configuration" select="input/configuration"/>
        <xsl:variable name="CompileOptionsPolicy" select="$configuration/CompileOptionsPolicy"/>
        <xsl:variable name="lang">
            <xsl:choose>
                <xsl:when test="input/locale">
                    <xsl:value-of select="input/locale"/>
                </xsl:when>
                <xsl:otherwise>en</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:for-each select="$CompileOptionsPolicy">
          <!-- The following options must be set
               WSIValidation=warn|fail, 
               WSDLValidateBody=strict,
               WSDLValidateHeaders=strict,
               WSDLValidateFaults=strict,
               WSDLWrappedFaults=false
               -->
          <xsl:if test="WSIValidation = 'ignore'">
            <Report type="Miscellaneous" severity="Fail">
              <Location object-type="CompileOptionsPolicy">
                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
              </Location>
              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bp.WSIValidation.details')"/></Details>
            </Report>
          </xsl:if>

          <xsl:if test="WSDLValidateBody != 'strict'">
            <Report type="Miscellaneous" severity="Fail">
              <Location object-type="CompileOptionsPolicy">
                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
              </Location>
              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bp.WSDLValidateBody.details')"/></Details>
            </Report>
          </xsl:if>

          <xsl:if test="WSDLValidateHeaders != 'strict'">
            <Report type="Miscellaneous" severity="Fail">
              <Location object-type="CompileOptionsPolicy">
                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
              </Location>
              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bp.WSDLValidateHeaders.details')"/></Details>
            </Report>
          </xsl:if>

          <xsl:if test="WSDLValidateFaults != 'strict'">
            <Report type="Miscellaneous" severity="Fail">
              <Location object-type="CompileOptionsPolicy">
                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
              </Location>
              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bp.WSDLValidateFaults.details')"/></Details>
            </Report>
          </xsl:if>

          <xsl:if test="WSDLWrappedFaults != 'off'">
            <Report type="Miscellaneous" severity="Fail">
              <Location object-type="CompileOptionsPolicy">
                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
              </Location>
              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bp.WSDLWrappedFaults.details')"/></Details>
            </Report>
          </xsl:if>
        </xsl:for-each>

        <xsl:variable name="XMLFirewallService" select="$configuration/XMLFirewallService"/>
        <xsl:for-each select="$XMLFirewallService">
          <xsl:if test="RequestType != 'soap'">
            <Report type="Conformance" severity="Fail" specification="BP1.0, BP1.1" requirement="R1008">
              <Location object-type="XMLFirewallService">
                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
              </Location>
              <ParameterName><xsl:value-of select="'RequestType'"/></ParameterName>
              <PermittedSetting>soap</PermittedSetting>
              <ActualSetting><xsl:value-of select="RequestType"/></ActualSetting>
              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bp.disallowDTD.details')"/></Details>
            </Report>
            <Report type="Conformance" severity="Fail" specification="BP1.0, BP1.1" requirement="R1009">
              <Location object-type="XMLFirewallService">
                <xsl:attribute name="object-name"><xsl:value-of select="@name"/></xsl:attribute>
              </Location>
              <ParameterName><xsl:value-of select="'RequestType'"/></ParameterName>
              <PermittedSetting>soap</PermittedSetting>
              <ActualSetting><xsl:value-of select="RequestType"/></ActualSetting>
              <Details><xsl:value-of select="dpfunc:get-message-by-lang($lang,'store.profiles.dp-wsi-bp.disallowPI.details')"/></Details>
            </Report>
          </xsl:if>
        </xsl:for-each>
      </ConformanceAnalysis>
    </xsl:template>
</xsl:stylesheet>
