<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2013. All Rights Reserved.
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
<!-- This stylesheet is complementary to pfw-setcontext.xsl. Its job is to return
     the rules to execute for policy enforcement on a response (or fault). It has two 
     modes (SLD and SLA)
     
     Example execution:
     
     Assume this policy enforcement context:
       <SLD Base="rest_4_1>
         <Rule Name="rest_4_1-2"/>
         <SLA Base="rest_4_1_sla1">
           <Rule Name="rest_4_1_sla1-2"/>
         </SLA>
       </SLD>
     
     SLD Mode case:
       BaseRule: null  (not needed)
       Mode:     SLD   (default value)
       
       Output (If not fault)
       <SLDCheck>
         <SLD Rule="rest_4_1-2-resp"/>
       </SLDCheck>  

     SLA Mode case:
       BaseRule: rest_4_1
       Mode:     SLA
       
       Output (If fault)
       <SLACheck>
         <SLA Rule="rest_4_1-sla1-2-process-fault"/>
       </SLACheck>  
       
       Also sets var://context/policy/enforcement-path-sld-alternative-rule = rest_4_1-2-process-fault
              
       Output (If not fault)
       <SLACheck>
         <SLA Rule="rest_4_1-sla1-2-process-resp"/>
       </SLACheck>  

       Also sets var://context/policy/enforcement-path-sld-alternative-rule = rest_4_1-2-process-resp
     
     -->
  <xsl:param name="dpconfig:BaseRule"    select="''"/>
  <xsl:param name="dpconfig:Mode"        select="'SLD'"/>  <!-- Valid modes are SLD or SLA -->

  <xsl:template match='/'>
    <xsl:variable name="policyEnforcementContext" select="dp:variable('var://context/policy/enforcement-path')"/>

    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="$dpconfig:Mode = 'SLD'"> <!-- SLD MODE -->
          <xsl:element name="SLDCheck">
            <xsl:for-each select="$policyEnforcementContext/SLD">
              <xsl:element name="SLD">
                <xsl:attribute name="Rule"><xsl:value-of select="concat(./@Base, '-resp')"/></xsl:attribute>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:when>
        
        <xsl:otherwise>                          <!-- SLA MODE -->
          <!-- Is the response a SOAP fault? -->
          <xsl:variable name="isSoapFault" select="string-length(/*[local-name()='Envelope' and (namespace-uri()='http://schemas.xmlsoap.org/soap/envelope/' or namespace-uri()='http://www.w3.org/2003/05/soap-envelope')]/*[local-name()='Body' and (namespace-uri()='http://schemas.xmlsoap.org/soap/envelope/' or namespace-uri()='http://www.w3.org/2003/05/soap-envelope')]/*[local-name()='Fault' and (namespace-uri()='http://schemas.xmlsoap.org/soap/envelope/' or namespace-uri()='http://www.w3.org/2003/05/soap-envelope')]) > 0"/>
      
          <!-- Is the response a REST fault? -->
          <xsl:variable name="isRestFault" select="dp:variable('var://context/policy/enforce-response-as-fault') = 'true'"/>
          
          <xsl:variable name="RuleSuffix">
            <xsl:choose>
              <xsl:when test="$isSoapFault or $isRestFault">
                <xsl:text>-process-fault</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>-process-resp</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
    
          <!-- Set a variable to the rulename for the alternative that was ultimately run for this SLD -->
          <dp:set-variable name="'var://context/policy/enforcement-path-sld-alternative-rule'" value="concat($policyEnforcementContext/SLD[@Base=$dpconfig:BaseRule]/Rule/@Name, $RuleSuffix)"/>

          <xsl:element name="SLACheck">
            <xsl:for-each select="$policyEnforcementContext/SLD[@Base=$dpconfig:BaseRule]/SLA">
              <xsl:element name="SLA">
                <xsl:attribute name="Rule"><xsl:value-of select="concat(./Rule/@Name, $RuleSuffix)"/></xsl:attribute>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:copy-of select="$result"/>

  </xsl:template>

</xsl:stylesheet>
