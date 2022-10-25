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
     exclude-result-prefixes="dp dpconfig"
>

  <xsl:include href="webgui:///DomainUtil.xsl" dp:ignore-multiple="yes"/>
  <xsl:include href="store:///dp/conformance-common.xsl" dp:ignore-multiple="yes"/>

  <dp:summary xmlns="">
      <operation>filter</operation>
      <suboperation>Conformance-filter</suboperation>
      <description>Profile Conformance filter</description>
      <descriptionId>store.conformance-filter.dpsummary.description</descriptionId>
  </dp:summary>

  <dp:param name="dpconfig:conformance-policy" type="dmReference" reftype="ConformancePolicy" xmlns="" subtype="ConformancePolicyFilter">
    <display>Conformance Policy</display>
    <displayId>store.conformance-filter.param.conformance-policy.display</displayId>
    <description>Policy specifying what conformance checks are to be made    
    </description>
    <descriptionId>store.conformance-filter.param.conformance-policy.description</descriptionId>
  </dp:param>

  <!-- All the input message should be valid against SOAP schema in WSI conformance checking.
       The schema validation is usually done by the service, such as XML Firewall, when the "Request Type"
       selects "SOAP". However, if the "Request Type" is not configured as "SOAP" but "XML", no schema
       validation was done. This setting can also put the schema violation into the conformance report.
       -->
  <dp:param name="dpconfig:validate-soap-schema" type="dmToggle" xmlns="">
    <display>Enforce SOAP Schema Conformance</display>
    <displayId>store.conformance-filter.param.validate-soap-schema.display</displayId>
    <description>    
    Setting to 'on' will additionally validate the input SOAP message against
    the SOAP 1.1 and SOAP 1.2 schemas. By default this setting is off.

    All the related SOAP schema files can be found via store:///schemas/soap-envelope.xsd.    
    </description>
    <descriptionId>store.conformance-filter.param.validate-soap-schema.description</descriptionId>
    <default>off</default>
  </dp:param>

  <xsl:template match="/">

    <xsl:apply-templates select="/" mode="check-conformance">
      <xsl:with-param name="mode" select="'filter'"/>
    </xsl:apply-templates>

  </xsl:template>

</xsl:stylesheet>
