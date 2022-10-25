<?xml version="1.0" encoding="utf-8"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2007. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
     When validating wsm / wsdl responses, the wsdl can provide schema
     for the fault/detail element of a soap fault.  Otherwise, the 
     wsdl can provide schema for the full soap:body/* .  This stylesheet
     extracts the appropriate nodes for validation. 
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp dpconfig"
>
  <xsl:output method="xml"/>
  <xsl:template match="/">
      <xsl:choose>
          <xsl:when test="./*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='Fault']">
               <Envelope>
                   <Body>
                      <xsl:copy-of select="./*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='Fault']/detail/*"/>
                   </Body>     
               </Envelope>
          </xsl:when>
          <xsl:otherwise>
              <xsl:copy-of select="."/>
          </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
