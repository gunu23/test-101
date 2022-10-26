<?xml version="1.0"?>
<!--
  Licensed Materials - Property of IBM
  IBM WebSphere DataPower Appliances
  Copyright IBM Corporation 2011,2014. All Rights Reserved.
  US Government Users Restricted Rights - Use, duplication or disclosure
  restricted by GSA ADP Schedule Contract with IBM Corp.
-->

<!--
    This stylesheet retrieves identity from a sld check results context variable
    and converts it into a format to be used by an SLM Policy 

    Example1:
	An input like this...
	<SLDCheck>
	  <SLD Rule="sld-service_16_2_1-req">
	    <Identity>
	      <Filter Name="Name1">Value1</Filter>
	      <Filter Name="Name2">Value2</Filter>
	    </Identity>
	  </SLD>
	</SLDCheck>
	
	Will result in this...
        <result>
	        <match/>
		<value>Name1!Value1:Name2!Value2</value>
	</result>
        
    Example2:
	An input like this...
	<SLDCheck>
	  <SLD Rule="sld-service_16_2_1-req">
	    <Identity>
	      <Filter>Value1</Filter>
	      <Filter>Value2</Filter>
	    </Identity>
	  </SLD>
	</SLDCheck>
	
	Will result in this...
        <result>
	        <match/>
		<value>!Value1:!Value2</value>
	</result>

    Example3:
	An input like this...
	<SLDCheck>
	  <SLD Rule="sld-service_16_2_1-req">
	    <Identity>
	      <Always/>
	    </Identity>
	  </SLD>
	</SLDCheck>
	
	Will result in this...
        <result>
	        <match/>
	</result>

    Example4:
	An empty input nodeset will result in this...
        <result/>
-->

<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
    xmlns:dp="http://www.datapower.com/extensions"
    xmlns:dpconfig="http://www.datapower.com/param/config"
    extension-element-prefixes="dp dpconfig"
    exclude-result-prefixes="dp dpconfig">

    <xsl:template match="/">

      <xsl:variable name="check-results" select="dp:variable('var://context/sld/check-results')"/>
      <!-- the base rule name is the portion of the rule that precedes the alternative, so use the portion of the name that precedes "-" -->
      <xsl:variable name="rule-name">
	<xsl:choose>
	  <xsl:when test="contains(dp:variable('var://service/transaction-rule-name'), '_sla')">
	    <!-- We need to find the resource class even if this was an SLA policy, so parse the base rule name by stripping off the '_slaN' -->
	    <xsl:value-of select="substring-before(dp:variable('var://service/transaction-rule-name'), '_sla')"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="substring-before(dp:variable('var://service/transaction-rule-name'), '-')"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
      <xsl:variable name="input" select="$check-results//*[@Base = $rule-name]//Identity/Filter"/>
      <xsl:variable name="always" select="$check-results//*[@Base = $rule-name]//Identity/Always"/>
      <xsl:variable name="filterElementCount" select="count($input)"/>
      <xsl:variable name="alwaysElementCount" select="count($always)"/>

      <xsl:variable name="output">
        <xsl:choose>
          <xsl:when test="$alwaysElementCount = 1">  <!-- always takes precedence over an identity if both are provided -->
            <xsl:element name="result">
              <xsl:element name="match"/>
	    </xsl:element>
          </xsl:when>
          <xsl:when test="$filterElementCount = 0">
            <xsl:element name="result"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="result">
              <xsl:element name="match"/>
              <xsl:element name="value">
                <xsl:variable name="outputTemp"> 
                  <xsl:for-each select="$input">
                    <xsl:value-of select="normalize-space(./@Name)"/><xsl:text>!</xsl:text><xsl:value-of select="normalize-space(.)"/><xsl:text>:</xsl:text>
                  </xsl:for-each>
                </xsl:variable>
		                
                <!-- strip off the last colon that was added -->
                <xsl:value-of select="substring($outputTemp, 1, number(string-length($outputTemp) -1))"/>
              </xsl:element>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:copy-of select="$output"/>

    </xsl:template>
</xsl:stylesheet>