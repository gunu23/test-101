<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2013. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This stylesheet sets context variables for the custom routing
    options in WS-MediationPolicy 1.7 spec. These context variables will be
    available to the Rules and Stylesheets that implement the custom routing
    algorithm.
-->

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dp dpconfig"
    exclude-result-prefixes="dp dpgui dpconfig">

    <xsl:import href="store:///mediation-util.xsl"/>

    <xsl:param name="dpconfig:Algorithm" select="''"/>
    <xsl:param name="dpconfig:EndPoints" select="''"/>
    <xsl:param name="dpconfig:Parameters" select="''"/>
    <xsl:param name="dpconfig:RoutingSSLProfile" select="''"/>
    <xsl:param name="dpconfig:RegistryServer" select="''"/>

    <xsl:template match="/">
      
      <!-- Add Algorithm as a context variable -->
      <dp:set-variable name="'var://context/mediation-policy/custom-routing-algorithm'" value="$dpconfig:Algorithm" />

      <!-- Add EndPoints as a context variable -->
      <xsl:variable name="parsedEndPoints">
          <dp:parse select="$dpconfig:EndPoints"/>
      </xsl:variable>
      <dp:set-variable name="'var://context/mediation-policy/custom-routing-endpoints'" value="$parsedEndPoints" />
  
      <!-- Add Parameters as a context variable -->
      <xsl:variable name="parsedParameters">
          <dp:parse select="$dpconfig:Parameters"/>
      </xsl:variable>
      <dp:set-variable name="'var://context/mediation-policy/custom-routing-parameters'" value="$parsedParameters" />
      
      <!-- Add routing ssl profile as a context variable -->
      <dp:set-variable name="'var://context/mediation-policy/custom-routing-ssl-profile'" value="$dpconfig:RoutingSSLProfile" />

      <!-- Add registry server as a context variable if provided -->
      <dp:set-variable name="'var://context/mediation-policy/custom-routing-registry-server'" value="$dpconfig:RegistryServer" />
    </xsl:template>

</xsl:stylesheet>
