<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2014,2015. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpfunc="http://www.datapower.com/extensions/functions"
    xmlns:func="http://exslt.org/functions"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="dp"
    exclude-result-prefixes="dp dpfunc func"
>
  
<!-- ************************** -->
<!-- UTILITY FUNCTION CODE HERE -->

  <!--
       Set vars within a policy context
  -->
  <func:function name="dpfunc:SetPolicyContextVar">
    <xsl:param name="value" select="''"/>
    <xsl:param name="name" select="''"/>

      <!-- Determine the variable name that this call requires -->
      <xsl:variable name="varName">
        <xsl:choose>
          <xsl:when test="string-length(dp:variable('var://context/policy/fw/current-context')) > 0">
            <xsl:value-of select="concat('var://context/policy/', dp:variable('var://context/policy/fw/current-context'), '/', $name)"/>
            <dp:set-local-variable name="'policy-ctx-found'" value="1"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Can't determine context name (not passed into function, and not available in transaction context)
                 but no worries, we'll just return zero saying so -->
            <dp:set-local-variable name="'policy-ctx-found'" value="0"/>
          </xsl:otherwise>
        </xsl:choose>  
      </xsl:variable>

      <xsl:if test="string-length(dp:variable('var://context/policy/fw/current-context')) > 0">
        <dp:set-variable name="$varName" value="string($value)"/>
      </xsl:if>

      <func:result select="dp:local-variable('policy-ctx-found')"/>
  </func:function>

  <!--
       Get vars within a policy context, this function looks in 2 places
       1) Looks in the policy context established by the framework (under var://context/policy/<context-name>/<var-name>)
           If (1) is an empty string then
       2) Retrieve the value from a property in current-policy 
  -->
  <func:function name="dpfunc:GetPolicyContextVar">
    <xsl:param name="name" select="''"/>
    <xsl:param name="context" select="''"/> <!-- optional -->

      <!-- Determine the variable name that this call requires -->
      <xsl:variable name="varName">
        <xsl:choose>
          <xsl:when test="$context = '_PREVIOUS_'">
            <xsl:value-of select="concat('var://context/policy/', dp:variable('var://context/policy/fw/previous-context'), '/', $name)"/>
          </xsl:when>
          <xsl:when test="string-length($context) > 0">
            <xsl:value-of select="concat('var://context/policy/', $context, '/', $name)"/>
          </xsl:when>
          <xsl:when test="string-length(dp:variable('var://context/policy/fw/current-context')) > 0">
            <xsl:value-of select="concat('var://context/policy/', dp:variable('var://context/policy/fw/current-context'), '/', $name)"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Can't determine context name (not passed into function, and not available in transaction context)
                 but no worries, we'll just return an empty node set -->
          </xsl:otherwise>
        </xsl:choose>  
      </xsl:variable>
      
      <xsl:variable name="value" select="dp:variable($varName)"/>

      <xsl:variable name="result">
        <xsl:choose>
          <xsl:when test="string-length($value) > 0 or string-length($context) > 0">
            <xsl:value-of select="$value"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="propertyValue" select="dp:variable('var://context/policy/fw/current-policy')/properties/property[@name=$name]/text()"/>

            <xsl:choose>
              <xsl:when test="string-length($propertyValue) = 0"> <!-- We did not find a value in context var or as a propety, perhaps it is an array? -->
                <xsl:variable name="propertyArray" select="dp:variable('var://context/policy/fw/current-policy')/properties//properties[@name=$name]"/>
                <xsl:copy-of select="$propertyArray"/>
              </xsl:when>
              <xsl:when test="contains($propertyValue, '{') and contains($propertyValue, '}')">
                <xsl:for-each select="str:split(substring($propertyValue, 2, string-length($propertyValue)-2),':')">
                  <xsl:choose>
                    <xsl:when test="string-length(dp:local-variable('policy-context-name')) = 0">
                      <dp:set-local-variable name="'policy-context-name'" value="."/>
                    </xsl:when>
                    <xsl:otherwise>
                      <dp:set-local-variable name="'policy-variable-name'" value="."/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>

                <!-- We found an indirect reference, recursively call GetPolicyContext to get the value from the referenced context -->
                <xsl:value-of select="dpfunc:GetPolicyContextVar(dp:local-variable('policy-variable-name'),dp:local-variable('policy-context-name'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$propertyValue"/>
              </xsl:otherwise>
            </xsl:choose>
            
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <func:result select="string($result)"/>
  </func:function>

  <!--
       Give the policy framework the plist of policies to enforce
  -->
  <func:function name="dpfunc:SetEnforcementMap">
    <xsl:param name="map" select="''"/>

      <dp:set-variable name="'var://context/policy/fw/input-map'" value="$map"/>
  </func:function>

  <!--
       Tell the policy framework which policy step to enforce next
  -->
  <func:function name="dpfunc:SetNextStep">
    <xsl:param name="context" select="''"/>

      <dp:set-variable name="'var://context/policy/fw/next-policy'" value="$context"/>
  </func:function>

  <!--
       Return the context name of the policy currently being enforced
  -->
  <func:function name="dpfunc:GetCurrentContext">
      <xsl:variable name="context" select="dp:variable('var://context/policy/fw/current-context')"/>

      <func:result select="$context"/>
  </func:function>

  <!--
       Return the xml description of the policy currently being enforced
  -->
  <func:function name="dpfunc:GetCurrentPolicy">
      <xsl:variable name="policy" select="dp:variable('var://context/policy/fw/current-policy')"/>

      <func:result select="$policy"/>
  </func:function>

  <!--
       Return the current policy enforcement debug trace 
  -->
  <func:function name="dpfunc:GetTrace">
      <xsl:variable name="trace" select="dp:variable('var://context/policy/fw/trace')"/>

      <func:result select="$trace"/>
  </func:function>


<!-- UTILITY FUNCTION CODE HERE -->
<!-- ************************** -->
  
</xsl:stylesheet>
