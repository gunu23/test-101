<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2011,2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dpe="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dpe"
    exclude-result-prefixes="dpe">

<!-- This stylesheet will run the sla-check stylesheets against the input.
     There may be up to four such stylesheets to run.  If no SLA rules will
     be matched and  the SLA Enforcement mode in the Policy Attachment was set
     to 'reject-if-no-sla', then will <reject> the request.  Otherwise,
     stores the number of SLA Rules that matched into 
     var://context/sla/matched-rule-count
-->
  <xsl:param name="dpconfig:endpoint_sla_check"     select="''"/>
  <xsl:param name="dpconfig:service_sla_check"      select="''"/>
  <xsl:param name="dpconfig:operation_sla_check"    select="''"/>
  <xsl:param name="dpconfig:message_sla_check"      select="''"/>
  <xsl:param name="dpconfig:rest_sla_check"         select="''"/>
  <xsl:param name="dpconfig:sla_enforcement_mode"   select="''"/>
  
  <xsl:template match='/'>
    <!-- change to append sla_check__result -->
    <xsl:variable name="endpoint_sla_check_result">
      <xsl:if test="string-length($dpconfig:endpoint_sla_check) != 0">
        <xsl:copy-of select="dpe:transform($dpconfig:endpoint_sla_check, .)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="service_sla_check_result">
      <xsl:if test="string-length($dpconfig:service_sla_check) != 0">
        <xsl:copy-of select="dpe:transform($dpconfig:service_sla_check, .)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="operation_sla_check_result">
      <xsl:if test="string-length($dpconfig:operation_sla_check) != 0">
        <xsl:copy-of select="dpe:transform($dpconfig:operation_sla_check, .)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="message_sla_check_result">
      <xsl:if test="string-length($dpconfig:message_sla_check) != 0">
        <xsl:copy-of select="dpe:transform($dpconfig:message_sla_check, .)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="rest_sla_check_result">
      <xsl:if test="string-length($dpconfig:rest_sla_check) != 0">
        <xsl:copy-of select="dpe:transform($dpconfig:rest_sla_check, .)"/>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="sla-rules-match-count" select="count($endpoint_sla_check_result/SLACheck/SLA) + count($service_sla_check_result/SLACheck/SLA) + count($operation_sla_check_result/SLACheck/SLA) + count($message_sla_check_result/SLACheck/SLA) + count($rest_sla_check_result/SLACheck/SLA)"/>
<!-- tracing 
    <xsl:message dpe:priority="critical">
      endpoint_check(<xsl:copy-of select="$endpoint_sla_check_result"/>)
    </xsl:message>
    <xsl:message dpe:priority="critical">
      service_check(<xsl:copy-of select="$service_sla_check_result"/>)
    </xsl:message>
    <xsl:message dpe:priority="critical">
      operation_check(<xsl:copy-of select="$operation_sla_check_result"/>)
    </xsl:message>
    <xsl:message dpe:priority="critical">
      message_check(<xsl:copy-of select="$message_sla_check_result"/>)
    </xsl:message>
    <xsl:message dpe:priority="critical">
      rest_check(<xsl:copy-of select="$rest_sla_check_result"/>)
    </xsl:message>    
    <xsl:message dpe:priority="critical">
      total rules matched(<xsl:value-of select="$sla-rules-match-count"/>)
    </xsl:message>
    <xsl:message dpe:priority="critical">
      sla-enforce-mode(<xsl:value-of select="$dpconfig:sla_enforcement_mode"/>)
    </xsl:message>
 -->

    <!-- output context var will contain the count for the SLAs that matched
        <SLARuleMatch count="3"/>
    -->
    <xsl:variable name="sla-rules-match-count-nodeset">
      <xsl:element name="SLARuleMatch">
          <xsl:attribute name="count">
            <xsl:value-of select="$sla-rules-match-count"/>
          </xsl:attribute>
      </xsl:element>
    </xsl:variable>
    
    <!-- store the count in a context which may be acquired later -->
    <dpe:set-variable name="'var://context/sla/matched-rule-count'" value="$sla-rules-match-count-nodeset"/>
    
    <!--
      Here we enforce the reject, this is the earliest point we can tell if any
      SLA rules were matched
    -->
    <xsl:if test="$dpconfig:sla_enforcement_mode = 'reject' and $sla-rules-match-count = 0 ">
      <!--
        Log a message cat Error indication rejection because of sla enforce mode
      -->
      <dpe:reject>Rejected by policy.</dpe:reject>
    </xsl:if>

  </xsl:template>

</xsl:stylesheet>

