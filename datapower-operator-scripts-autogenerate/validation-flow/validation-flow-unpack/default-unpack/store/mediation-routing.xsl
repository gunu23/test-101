<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2011,2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This stylesheet will set the var://service/routing-url to the given input.
    If not provided in the input EndPoint parameter, the protocol, port, and/or URI will be taken from the
    service's configured endpoint destination.
-->

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:func="http://exslt.org/functions"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dp dpconfig"
    exclude-result-prefixes="dp dpgui dpconfig">

    <xsl:import href="store:///mediation-util.xsl"/>
    <xsl:import href="store:///policy-enforce-utility.xsl"/>

    <xsl:param name="dpconfig:EndPoint" select="''"/>
    <xsl:param name="dpconfig:RoutingSSLProfile" select="''"/>
    <xsl:param name="dpconfig:RouteVariable" select="''"/>
    
    <xsl:template match="/">
      <xsl:variable name="oldBackend" select="dp:variable('var://service/URL-out')"/>
      <xsl:variable name="newBackend">
        <xsl:choose>
          <xsl:when test="string-length($dpconfig:RouteVariable) > 0">
            <xsl:variable name="contextVariableRoute" select="dpfunc:GetPolicyContextVar($dpconfig:RouteVariable)"/>
            <xsl:variable name="variableRoute" select="dp:variable(concat('var://context/policy/ws-mediationpolicy/var/',$dpconfig:RouteVariable))"/>
            <xsl:choose>
              <xsl:when test="string-length($contextVariableRoute) > 0">
                <xsl:value-of select="$contextVariableRoute"/>  <!-- variable was declared in policy, and set prior to enforcement in the policy context, use the context value -->
              </xsl:when>
              <xsl:when test="string-length($variableRoute) > 0">
                <xsl:value-of select="$variableRoute"/>  <!-- variable was declared in policy, and set prior to enforcement, use the variable value -->
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$dpconfig:EndPoint"/>  <!-- variable was declared in policy, but not set - use the default value -->
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
                <xsl:value-of select="$dpconfig:EndPoint"/>  <!-- variable was not declared in policy -->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="string-length($newBackend) > 0"> <!-- it is possible to declare a policy var without a default. If that happens, and there is no var set then there is no route to change, skip -->
        <xsl:if test="string-length($dpconfig:RoutingSSLProfile) != 0">
          <dp:set-variable name="'var://service/routing-url-sslprofile'" value="string($dpconfig:RoutingSSLProfile)" />
        </xsl:if>
        
        <xsl:variable name="oldBackendParts" select="dpfunc:splitURL($oldBackend)"/>
        <xsl:variable name="newBackendParts" select="dpfunc:splitURL($newBackend)"/>
        
        <!-- Now that we have the "parts" of the new and old backends, assemble the "compiled" backend -->
        <xsl:variable name="compiledBackend">
          
          <!-- Use the protocol from the new backend, unless it was not specified - in which case we use the old backend protocol -->
          <xsl:choose>
            <xsl:when test="string-length($newBackendParts//protocol) = 0">
              <xsl:value-of select="concat($oldBackendParts//protocol, '://')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat($newBackendParts//protocol, '://')"/>
            </xsl:otherwise>
          </xsl:choose>
          
          <!-- Always use the hostname of the new backend -->
          <xsl:choose>
            <xsl:when test="string-length($newBackendParts//host) = 0">
              <xsl:value-of select="$oldBackendParts//host"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$newBackendParts//host"/>
            </xsl:otherwise>
          </xsl:choose>
          
          <xsl:choose>
            <xsl:when test="string-length($newBackendParts//port) = 0">
              <xsl:value-of select="concat(':', $oldBackendParts//port)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat(':', $newBackendParts//port)"/>
            </xsl:otherwise>
          </xsl:choose>
          
          <xsl:choose>
            <xsl:when test="string-length($newBackendParts//uri) = 0">
              <xsl:value-of select="$oldBackendParts//uri"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$newBackendParts//uri"/>
            </xsl:otherwise>
          </xsl:choose>
          
          <!-- If url parameters were specified on the old backend, pass them on to the new backend -->
          <xsl:if test="string-length($oldBackendParts//params) > 0">
            <xsl:value-of select="concat('?', $oldBackendParts//params)"/>
          </xsl:if>
        </xsl:variable>
  
        <dp:set-variable name="'var://service/routing-url'" value="string($compiledBackend)" />
      </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>