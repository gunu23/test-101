<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dpe="http://www.datapower.com/extensions"
    extension-element-prefixes="dpe"
    exclude-result-prefixes="dpe">

    <!-- This stylesheet will run the custom-check stylesheet against the input. -->
    <!-- The XSL is in charge of outputing the input to the next rule.           -->

    <xsl:template match='/'>
      <xsl:variable name="custom_check_endpoint"  select="dpe:variable('var://context/policy/mcf/custom/_endpoint_')"/>
      <xsl:variable name="custom_check_service"   select="dpe:variable('var://context/policy/mcf/custom/_service_')"/>
      <xsl:variable name="custom_check_operation" select="dpe:variable('var://context/policy/mcf/custom/_operation_')"/>
      <xsl:variable name="custom_check_message"   select="dpe:variable('var://context/policy/mcf/custom/_message_')"/>
      
      <xsl:if test="string-length($custom_check_endpoint) != 0">
        <xsl:copy-of select="dpe:transform($custom_check_endpoint, .)"/>
      </xsl:if>
      
      <xsl:if test="string-length($custom_check_service) != 0">
        <xsl:copy-of select="dpe:transform($custom_check_service, .)"/>
      </xsl:if>
      
      <xsl:if test="string-length($custom_check_operation) != 0">
        <xsl:copy-of select="dpe:transform($custom_check_operation, .)"/>
      </xsl:if>
      
      <xsl:if test="string-length($custom_check_message) != 0">
        <xsl:copy-of select="dpe:transform($custom_check_message, .)"/>
      </xsl:if>      
    </xsl:template>
</xsl:stylesheet>

